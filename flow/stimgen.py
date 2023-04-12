#!/usr/bin/env python

import csv, os, tabulate
from enum import Enum

soclabs_header = """;#-----------------------------------------------------------------------------
;# SoC Labs Basic Hashing Accelerator Wrapper Input Stimulus File
;# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
;#
;# Contributors
;#
;# David Mapstone (d.a.mapstone@soton.ac.uk)
;#
;# Copyright  2023, SoC Labs (www.soclabs.org)
;#-----------------------------------------------------------------------------"""

class TransactionType(Enum):
    """ Enumerated Types for Transaction Types for ASCII Debug """
    READ  = 1
    WRITE = 2
    def __str__(self):
        if (self == TransactionType.READ):
            return "R"
        elif (self == TransactionType.WRITE):
            return "W"

class TransactionSize(Enum):
    """ Enumerated Types for Transaction Types for ASCII Debug """
    WORD     = 1
    HALFWORD = 2
    def __str__(self):
        if (self == TransactionSize.WORD):
            return "word"
        elif (self == TransactionSize.HALFWORD):
            return "halfword"

class InputBlockStruct:
    def __init__(self):
        self.word_list = []
    
    def word_append(self, word):
        self.word_list.append(word)

class InputPacketStruct:
    def __init__(self):
        self.block_list = []
    
    def block_append(self, block):
        self.block_list.append(block)

class WordStruct:
    def __init__(self, data, addr, trans, packet_num = 0, block_num = 0, size = TransactionSize.WORD):
        self.data = data
        self.addr = addr
        self.trans = trans
        self.packet_num = packet_num
        self.block_num = block_num
        self.size = size

def adp_output(out_file, word_list):
    """ 
    This function takes a list of 32 bit words and addresses and formats 
    the data into .cmd format for the ADP module
    testbench
    """
    
    data = []
    for word in word_list:
        if (word.data > 0):
            data.append(["a", "{0:#0{1}x}".format(word.addr,10)])
            data.append([str(word.trans).lower(), "{0:#0{1}x}".format(word.data,10)])
    
    table_str = tabulate.tabulate(data, tablefmt="plain")

    with open(out_file, "w", encoding="UTF8", newline='') as f:
        f.write("A\n")
        f.write(table_str)
        f.write("\n  A")
        f.write("\nX")
        f.write("\n!")

def fri_output(out_file, word_list):
    """ 
    This function takes a list of 32 bit words and addresses and formats 
    the data into .fri format to be fed into fml2conv.pl script to stimulate
    testbench
    """
    
    # Column Names
    col_names = ["Transaction", "Address", "Data", "Size"]

    data = []
    for word in word_list:
        if (word.data > 0):
            data.append([str(word.trans), "{0:#0{1}x}".format(word.addr,10), "{0:#0{1}x}".format(word.data,10), str(word.size)])
    
    table_str = tabulate.tabulate(data, headers=col_names, tablefmt="plain")

    with open(out_file, "w", encoding="UTF8", newline='') as f:
        f.write(soclabs_header + "\n;")
        f.write(table_str)
        f.write("\nQ") # Add End of Simulation Flag

def stimulus_generation(stim_file, ref_file, input_start_address, input_size, output_start_address, output_size, gen_fri=True):
    """ 
    This function takes 32 bit input stimulus file from accelerator model,
    calculates write addresses for each word and generates a .fri file which
    can be used to stimulate an AHB testbench
    """
    fri_file = os.environ["PROJECT_DIR"] + "/wrapper/stimulus/" + "ahb_input_hash_stim.fri"

    if gen_fri:
        # Calculate End Address
        input_end_address = input_start_address + input_size - 0x4
        # print(f"End Address is {hex(end_address)}")

        # Open Files
        with open(stim_file, "r") as stim:
            csvreader = csv.reader(stim, delimiter=",")
            stim_list = list(csvreader)

        with open(ref_file, "r") as ref:
            csvreader = csv.reader(ref, delimiter=",")
            ref_list = list(csvreader)

        # Initialise Packet Lists
        write_packet_list = []
        read_packet_list  = []

        # Initialise Temporary Structures
        temppacketstruct = InputPacketStruct()
        tempblockstruct = InputBlockStruct()

        # Put Write Data into Structs
        for i in stim_list:
            tempblockstruct.word_append(int(i[0],16))
            # If Last Word in Block, Append to Packet and Reset Temporary block structure
            if (int(i[1])):
                temppacketstruct.block_append(tempblockstruct)
                tempblockstruct = InputBlockStruct()
                # If Last Block in Packet , Append Packet to Packet List and Reset Temp Packet
                if (int(i[2])):
                    write_packet_list.append(temppacketstruct)
                    temppacketstruct = InputPacketStruct()

        # Put Read Data into Structs
        for i in ref_list:
            tempblockstruct.word_append(int(i[0],16))
            # If Last Word in Block, Append to Packet and Reset Temporary block structure
            if (int(i[1])):
                temppacketstruct.block_append(tempblockstruct)
                tempblockstruct = InputBlockStruct()
                # If Last Block in Packet , Append Packet to Packet List and Reset Temp Packet
                if (int(i[2])):
                    read_packet_list.append(temppacketstruct)
                    temppacketstruct = InputPacketStruct()
            
        
        # List of Ouptut Transactions
        output_word_list = []

        # Generate Address for Packet
        for packet_num, write_packet in enumerate(write_packet_list):
            # Calculate Number of Blocks in First Packet
            num_blocks = len(write_packet.block_list)
            # Each Write Block Can Contain 16 32-bit Words (512 bits) (0x4 * 16 = 0x40)
            # - Work Out Required Size = (0x40 * NumBlocks)
            # - Work Out Beginning Address = (end_address + 0x4) - Size
            req_write_size = 0x40 * num_blocks
            start_write_addr = input_start_address + input_size - req_write_size
            # Each Read Block Contains 8 32-bit Words (256 bits) (0x4 * 8 = 0x20)
            req_read_size  = 0x20
            start_read_addr  = output_start_address + output_size - req_read_size
            # print(f"Packet: {int(packet_num)} | Start Address: {hex(start_write_addr)}")
            write_addr = start_write_addr
            read_addr  = start_read_addr
            # Write out Packet containing multiple 512 bit Blocks to Input Port
            for block_num, block in enumerate(write_packet.block_list):
                for word in block.word_list:
                    word_data = WordStruct(word, write_addr, TransactionType.WRITE, packet_num, block_num)
                    output_word_list.append(word_data)
                    # Increment Address
                    write_addr += 0x4
            # Set Read Packet
            read_packet = read_packet_list[packet_num]
            # Read Back 256 Bit Packet from Output Port
            for block_num, block in enumerate(read_packet.block_list):
                for word in block.word_list:
                    word_data = WordStruct(word, read_addr, TransactionType.READ, packet_num, 0)
                    output_word_list.append(word_data)
                    # Increment Address
                    read_addr += 0x4


        # Generate ADP Command File with Write Transactions
        adp_file = os.environ["PROJECT_DIR"] + "/system/stimulus/" + "adp_hash_stim.cmd"
        adp_output(adp_file, output_word_list)

        # Generate FRI File with Write Transactions
        fri_output(fri_file, output_word_list)

    # Call fm2conv.pl script
    m2d_file = os.environ["PROJECT_DIR"] + "/wrapper/stimulus/" + "ahb_input_hash_stim.m2d"
    os.system(f"fm2conv.pl -busWidth=32 -infile={fri_file} -outfile={m2d_file}")


if __name__ == "__main__":
    accelerator_input_address =  0x6001_0000
    accelerator_input_size =     0x0000_0400
    accelerator_output_address = 0x6001_0400
    accelerator_output_size =    0x0000_0400
    stim_file = os.environ["PROJECT_DIR"] + "/wrapper/stimulus/" + "input_block_32bit_stim.csv"
    ref_file = os.environ["PROJECT_DIR"] + "/wrapper/stimulus/" + "output_hash_32bit_ref.csv"
    stimulus_generation(stim_file, ref_file, accelerator_input_address, accelerator_input_size, accelerator_output_address, accelerator_output_size, gen_fri=False)