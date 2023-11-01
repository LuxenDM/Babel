import sys
import configparser
from unidecode import unidecode

def process_ini_file(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as infile:
        ini_content = infile.read()

    # Transliterate the INI file content to remove accents
    ini_content = unidecode(ini_content)

    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.write(ini_content)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py input.ini output.ini")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    process_ini_file(input_file, output_file)
    print(f"INI file '{input_file}' processed, and the result is saved to '{output_file}'.")
