import random
import numpy as np
import pandas as pd

def parse_grammar_file(filename):
    """
    Read nonterminals and terminals from a file and create a single dictionary with 0-based indexing.
    
    Args:
        filename: Path to the input file
        
    Returns:
        dict: Dictionary mapping all tokens to their 0-based indices
    """
    token_dict = {}
    
    with open(filename, 'r') as f:
        content = f.read()
    
    # Split by the separator line
    sections = content.split('=' * 50)
    
    # Process the first section
    lines = sections[0].strip().split('\n')
    
    current_section = None
    non_terms = 0
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        if line == 'NONTERMINALS':
            current_section = 'nonterminals'
        elif line == 'TERMINALS':
            current_section = 'terminals'
        elif line == 'BINARY RULES':
            current_section = 'binary_rules'
            count_mat = np.zeros((non_terms,(non_terms)*non_terms + len(token_dict) - non_terms))
        elif line == 'TERMINAL RULES':
            current_section = 'terminal_rules'
        else:
            # Split the line by whitespace to get individual tokens
            tokens = line.replace(',','').split()
            
            if current_section in ['nonterminals', 'terminals']:
                for token in tokens:
                    if token not in token_dict:
                        token_dict[token] = len(token_dict)
                        if current_section == 'nonterminals':
                            non_terms = non_terms + 1
            elif current_section in ['binary_rules','terminal_rules']:
                if current_section == 'binary_rules':
                    count_mat[token_dict[tokens[0]],token_dict[tokens[1]]*non_terms + token_dict[tokens[2]]] = tokens[3]
                if current_section == 'terminal_rules':
                    count_mat[token_dict[tokens[0]],non_terms*(non_terms-1)  + token_dict[tokens[2]]] = tokens[3]
                    
            
    
    return token_dict, count_mat, non_terms

def main():
    a,b,non_terms = parse_grammar_file("pcfg_rules.txt")

    terms = list(a.keys())[non_terms:]
    # Define headers
    row_headers = [list(a.keys())[0:non_terms]]
    col_headers = [(x, y) for x in list(a.keys())[0:non_terms] for y in list(a.keys())[0:non_terms]] + terms

# Create a DataFrame
    row_sums = b.sum(axis=1)
    df_norm= b / row_sums[:, np.newaxis]
    df_norm = pd.DataFrame( df_norm, index=row_headers, columns=col_headers)

    df_coded = ~np.all(df_norm == 0, axis=0)

    df_nonzero= df_norm.loc[:,df_coded]

    cdf_nonzero = np.cumsum(df_nonzero, axis=1)

    cdf_nonzero.to_csv('cdf_matrix_with_headers.csv')


    print("Matrix with headers saved to matrix_with_headers.csv")



if __name__ == "__main__":
    main()
"""
class Node:
    def __init__(self, value):
        self.value = value
        if(value in ["NT_1","NT_2","NT_3","NT_4","NT_5","NT_6", "NT_7","NT_8","NT_9", "NT_10",
                     "NT_11","NT_12","NT_13","NT_14","NT_15"]):
            self.right = None
            self.left = None
        else:
            self.right = Node(value - 1)
            self.left = Node(value - 1)
        
class probalisticTree:
    def __init__(self):
        self.root = None

    def insert(self, value):
        if not self.root:
            self.root = Node(value)
        else:
            self._insert_rec(self.root, value)

    def _insert_rec(self, node, value):
        if value < node.value:
            if node.left is None:
                node.left = Node(value)
            else:
                self._insert_rec(node.left, value)
        else:
            if node.right is None:
                node.right = Node(value)
            else:
                self._insert_rec(node.right, value)
"""