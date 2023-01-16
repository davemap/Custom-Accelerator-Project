#-----------------------------------------------------------------------------
# SoC Labs Basic SHA-2 Hashing Model Python Reference
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2022, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

import os, random, math, csv
import binascii
import hashlib

def main():
    # Check Environment Variables set
    if not "SHA_2_ACC_DIR" in os.environ:
        print("Sourceme file at root of repository has not been sourced. Please source this file and try again.")
        quit()
    # Read in Descriptor File
    # - contains number of packets of data to generate and random seed
    stim_file = os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/model/" + "model_stim.csv"
    with open(stim_file, "r") as stim:
        csvreader = csv.reader(stim, delimiter=",")
        stim_list = list(csvreader)
    
    seed        = int(stim_list[0][0])
    packets     = int(stim_list[0][1])
    gap_limit   = int(stim_list[0][2])
    stall_limit = int(stim_list[0][3])
    random.seed(seed)
    
    print(f"Generating {packets} packets using seed: {seed}")
    in_cfg_words_list = []
    in_cfg_words_gap_list = []
    sync_cfg_size_list = []
    sync_cfg_id_list = []
    sync_cfg_stall_list = []
    in_data_words_list = []
    in_data_words_last_list = []
    in_data_words_gap_list = []
    message_block_list = []
    message_block_last_list = []
    message_block_gap_list = []
    message_block_stall_list = []
    hash_list = []
    hash_stall_list = []
    # ID Lists
    id_gap_list = []
    expected_id_list = []
    expected_id_stall_list = []
    
    id_value = 0
    for i in range(packets):
        # Generate Gapping and Stalling Values
        #   Gapping - Period to wait before taking Input Valid High
        #   Stalling - Period to wait before taking Output Read High
        if gap_limit > 0:
            id_gap_list.append(random.randrange(0,gap_limit))
            in_cfg_words_gap_list.append(random.randrange(0,gap_limit))
        else:
            id_gap_list.append(0)
            in_cfg_words_gap_list.append(0)
        
        if stall_limit > 0:
            hash_stall_list.append(random.randrange(0,stall_limit))
            sync_cfg_stall_list.append(random.randrange(0,stall_limit))
        else:
            hash_stall_list.append(0)
            sync_cfg_stall_list.append(0)
        
        # Generate expected output in 512 bit chunks
        cfg_size = math.ceil(random.randint(0,pow(2,14))/8)*8
        cfg_size_bin = "{0:b}".format(cfg_size)
        # Pad Size to 64 bits
        cfg_size_str = "0"*(64-len(cfg_size_bin)) + str(cfg_size_bin)
        
        # Generate Random Data using Size
        data = "{0:b}".format(random.getrandbits(cfg_size))
        data = "0"*(cfg_size - len(data)) + data # Pad Data to length of config (Python like to concatenate values)
        
        if stall_limit > 0:
            id_stall_value = random.randrange(0,stall_limit)
        else:
            id_stall_value = 0
        
        expected_id_list.append(id_value)
        sync_cfg_id_list.append(id_value)

        
        # Reference Values
        id_value += 1
            
        if id_value >= 64:
            id_value = id_value - 64
        
        expected_id_stall_list.append(id_stall_value)
        
        chunked_data_words = chunkstring(str(data),512)
        in_data_words = chunked_data_words.copy()
        in_data_words[-1] = in_data_words[-1] + "0"*(512-len(in_data_words[-1]))
        in_data_words_last = []
        in_data_words_gap = []
        message_block = chunked_data_words.copy()
        message_block_last = []
        message_block_stall = []
        message_block_gap = []
        last_len = len(chunked_data_words[-1])
        # print(f"{chunked_data_words[-1]} {last_len}")
        if (last_len == 512):
            message_block.append("1" + "0"*447 + cfg_size_str)
        else:
            message_block[-1] = message_block[-1] + "1"
            if last_len > 447: # Size can't fit in last word
                # Pad last word to 512 bits
                message_block[-1] = message_block[-1] + "0"*(512 - len(message_block[-1]))
                # Create New word with Size at the end
                message_block.append("0"*448 + cfg_size_str)
            else:
                message_block[-1] = message_block[-1] + "0"*(512 - 64- len(message_block[-1])) + cfg_size_str
        
        for i in range(len(in_data_words)):
            in_data_words_last.append("0")  
            if gap_limit > 0:
                in_data_words_gap.append(random.randrange(0,gap_limit))
            else:
                in_data_words_gap.append(0)
        in_data_words_last[-1] = "1"
        
        for i in range(len(message_block)):
            message_block_last.append("0")
            if stall_limit > 0:
                message_block_stall.append(random.randrange(0,stall_limit))
            else:
                message_block_stall.append(0)
            if gap_limit > 0:
                message_block_gap.append(random.randrange(0,gap_limit))
            else:
                message_block_gap.append(0)
        message_block_last[-1] = "1"
        
        in_cfg_words_list.append(cfg_size_str)
        sync_cfg_size_list.append(cfg_size_str)
        in_data_words_list       += in_data_words
        in_data_words_last_list  += in_data_words_last
        in_data_words_gap_list   += in_data_words_gap
        message_block_list       += message_block
        message_block_last_list  += message_block_last
        message_block_gap_list   += message_block_gap
        message_block_stall_list += message_block_stall
        intval = int(data, 2)
        hash_val = 0
        h=int(data, 2).to_bytes((len(data) + 7) // 8, byteorder='big')
        hash_val = binascii.hexlify(hashlib.sha256(h).digest()).decode()
        hash_list.append(hash_val)

    # Write out Input ID Seed to Text File
    input_header = ["id_seed", "use_seed", "last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "input_id_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(expected_id_list):
            writer.writerow([expected_id_list[idx], "1", id_gap_list[idx]])
            
    # Write out Output ID Values to Text File
    input_header = ["expected_id_value, id_last, stall_value"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "output_id_ref.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(expected_id_list):
            writer.writerow([word, "1", expected_id_stall_list[idx]])
    
    # Write out Input Data Stimulus to Text File
    input_header = ["input_data", "input_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "input_data_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(in_data_words_list):
            writer.writerow(["{0:x}".format(int(word, 2)), in_data_words_last_list[idx], in_data_words_gap_list[idx]])
            
    # Write out Cfg Stimulus to Text File
    input_header = ["input_cfg_size", "input_cfg_scheme", "input_cfg_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "input_cfg_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(in_cfg_words_list):
            writer.writerow(["{0:x}".format(int(word, 2)), "0", "1", in_cfg_words_gap_list[idx]])
        
    # Write out Cfg sync reference to Text File
    input_header = ["input_cfg_size", "input_cfg_scheme", "input_cfg_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "output_cfg_sync_ref.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(sync_cfg_size_list):
            writer.writerow(["{0:x}".format(int(word, 2)), "0", sync_cfg_id_list[idx], "1", sync_cfg_stall_list[idx]])
            
    # Write out Expected output to text file
    output_header = ["output_data", "output_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "output_message_block_ref.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(message_block_list):
            writer.writerow(["{0:x}".format(int(word, 2)), message_block_last_list[idx], message_block_stall_list[idx]])

    # Write out Message Block (Input) to text file
    output_header = ["message_block_data", "message_block_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "input_message_block_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(message_block_list):
            writer.writerow(["{0:x}".format(int(word, 2)), message_block_last_list[idx], message_block_gap_list[idx]])
    
    # Write out hash value to text file
    output_header = ["output_data", "output_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/testbench/" + "output_hash_ref.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(hash_list):
            writer.writerow([word, "1", hash_stall_list[idx]])
    
def chunkstring(string, length):
    array_len = math.ceil(len(string)/length)
    array = []
    for i in range(array_len):
        array.append(string[i*length:i*length + length])
    return array

if __name__ == "__main__":
    main()
