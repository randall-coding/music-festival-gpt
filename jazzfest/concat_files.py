import sys
output_file = sys.argv[1]
file_names = sys.argv[2]

# file_name format is "[\"jazz_fest_1_lineup.txt\",\"jazz_fest_2_lineup.txt\"]"
file_names = file_names[1:-1].replace('"', '').split(',')

with open(output_file, 'w') as outfile:
    for fname in file_names:
        with open(fname.replace(" ", "")) as infile:
            outfile.write(infile.read())
            outfile.write('\n')