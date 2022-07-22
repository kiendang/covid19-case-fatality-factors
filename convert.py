"""convert the provided 'msa_dict.pkl' file to json"""

from pathlib import Path
import json
import pickle


DATA_DIR = Path(__file__).parent / 'data'


def main():
    with open(DATA_DIR / 'msa_dict.pkl', 'rb') as f:
        msa_dict = pickle.load(f)

    with open(DATA_DIR / 'msa_dict.json', 'w') as f:
        json.dump(msa_dict, f)


if __name__ == '__main__':
    main()
