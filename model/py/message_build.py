#-----------------------------------------------------------------------------
# SoC Labs Basic SHA-2 Message Builder Python Reference
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2022, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

import os, sys, random, math, csv

def main(argv):
    # Check Environment Variables set
    if not "SHA_2_ACC_DIR" in os.environ:
        print("Sourceme file at root of repository has not been sourced. Please source this file and try again.")
        quit()
    # Read in Descriptor File
    # - contains number of packets of data to generate and random seed
    # input_file = argv[1]
    seed = 1 # Needs to be loaded in from file
    packets = 1
    random.seed(seed)
    
    print(f"Generating {packets} packets using seed: {seed}")
    cfg_words_list = []
    in_data_words_list = []
    in_data_words_last_list = []
    out_data_words_list = []
    out_data_words_last_list = []
    
    for i in range(packets):
        # Generate expected output in 512 bit chunks
        cfg_size = random.randint(0,pow(2,14))
        cfg_size_bin = "{0:b}".format(cfg_size)
        # Pad Size to 64 bits
        cfg_size_str = "0"*(64-len(cfg_size_bin)) + str(cfg_size_bin)
        
        # Generate Random Data using Size
        data = "{0:b}".format(random.getrandbits(cfg_size))
        
        chunked_data_words = chunkstring(str(data),512)
        in_data_words = chunked_data_words.copy()
        in_data_words[-1] = in_data_words[-1] + "0"*(512-len(in_data_words[-1]))
        in_data_words_last = []
        out_data_words = chunked_data_words.copy()
        out_data_words_last = []
        last_len = len(chunked_data_words[-1])
        if (last_len == 512):
            out_data_words.append("1" + "0"*447 + cfg_size_str)
        else:
            out_data_words[-1] = out_data_words[-1] + "1"
            if last_len > 447: # Size can't fit in last word
                # Pad last word to 512 bits
                out_data_words[-1] = out_data_words[-1] + "0"*(512 - len(out_data_words[-1]))
                # Create New word with Size at the end
                out_data_words.append("0"*448 + cfg_size_str)
            else:
                out_data_words[-1] = out_data_words[-1] + "0"*(512 - 64- len(out_data_words[-1])) + cfg_size_str
        
        for i in range(len(in_data_words) - 1):
            in_data_words_last.append("0")
        in_data_words_last.append("1")
        
        for i in range(len(out_data_words) - 1):
            out_data_words_last.append("0")
        out_data_words_last.append("1")
        
        cfg_words_list.append(cfg_size_str)
        in_data_words_list += in_data_words
        in_data_words_last_list += in_data_words_last
        out_data_words_list += out_data_words
        out_data_words_last_list += out_data_words_last

    # Write out Input Data Stimulus to Text File
    input_header = ["input_data", "input_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/" + "input_data_builder_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(in_data_words_list):
            writer.writerow(["{0:x}".format(int(word, 2)), in_data_words_last_list[idx]])
            
    # Write out Cfg Stimulus to Text File
    input_header = ["input_cfg_size", "input_cfg_scheme", "input_cfg_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/" + "input_cfg_builder_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(cfg_words_list):
            writer.writerow(["{0:x}".format(int(word, 2)), "0", "1"])
            
    # Write out Expected output to text file
    output_header = ["output_data", "output_data_last"]
    with open(os.environ["SHA_2_ACC_DIR"] + "/simulate/stimulus/" + "output_data_builder_stim.csv", "w", encoding="UTF8", newline='') as f:
        writer = csv.writer(f)
        for idx, word in enumerate(out_data_words_list):
            writer.writerow(["{0:x}".format(int(word, 2)), out_data_words_last_list[idx]])

def chunkstring(string, length):
    array_len = math.ceil(len(string)/length)
    array = []
    for i in range(array_len):
        array.append(string[i*length:i*length + length])
    return array

if __name__ == "__main__":
    main(sys.argv[1:])
