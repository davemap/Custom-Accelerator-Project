import yaml, os
from yaml.loader import SafeLoader
from pprint import pprint

class wrapper_class:
    def __init__ (self, name, engine_name,size):
        self.name   = name
        self.engine = engine_name
        self.size   = size

def generate(yaml_file):
    print("Generating")
    with open(yaml_file) as f:
        data = yaml.load(f, Loader=SafeLoader)
        pprint(data)
        # print(data)

if __name__ == "__main__":
    yaml_file = os.environ["SOC_TOP_DIR"] + "/wrapper/yaml/" + "secworks_sha256.yaml"
    generate(yaml_file)