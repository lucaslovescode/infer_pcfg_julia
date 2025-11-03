import numpy as np
import pandas as pd
import random
import ast

def sample_from_cumulative(cumulative_probs):
    """Sample an index from cumulative probability distribution."""
    r = random.random()
    return np.searchsorted(cumulative_probs, r)

def parse_column_header(header):
    """
    Parse column header to extract symbol information.
    Returns the symbol (terminal or nonterminal).
    """
    header = header.strip()
    
    # Check if it's a tuple (nonterminal pair)
    if header.startswith("(") and header.endswith(")"):
        try:
            return ast.literal_eval(header)  # Returns tuple like ('NT_1', 'NT_2')
        except:
            return header
    
    # Terminal symbol or other
    return header

def get_nonterminal_row_index(matrix_df, nonterminal):
    """Find the row index for a given nonterminal."""
    # If the matrix has a row index with nonterminals
    if nonterminal in matrix_df.index:
        return matrix_df.index.get_loc(nonterminal)
    
    # Otherwise, use a hash-based mapping
    nt_number = int(nonterminal.split('_')[1]) if '_' in nonterminal else 0
    return nt_number % len(matrix_df)

def generate_random_molecule(matrix_df, start_symbol='NT_1', max_depth=50):
    """
    Generate a random molecule string using a cumulative probability matrix.
    
    Args:
        matrix_df: DataFrame containing cumulative probability matrix
        start_symbol: The starting nonterminal symbol
        max_depth: Maximum recursion depth
        
    Returns:
        str: Generated molecule string
    """
    def _generate(symbol, depth):
        if depth >= max_depth:
            return ""
        
        # Get the appropriate row for current nonterminal
        row_idx = get_nonterminal_row_index(matrix_df, symbol)
        cumulative_probs = matrix_df.iloc[row_idx].values
        
        # Sample next symbol from cumulative distribution
        symbol_idx = sample_from_cumulative(cumulative_probs)
        next_symbol = parse_column_header(matrix_df.columns[symbol_idx])
        
        # Handle different symbol types
        if isinstance(next_symbol, tuple):
            # It's a nonterminal transition (NT_x, NT_y)
            # Recursively expand the second nonterminal
            left = _generate(next_symbol[0], depth + 1)
            right = _generate(next_symbol[1], depth + 1)
            return left + right
        
        elif isinstance(next_symbol, str) and next_symbol.startswith("[") and next_symbol.endswith("]"):
            # It's a terminal symbol - return it
            return next_symbol
        
        elif isinstance(next_symbol, str) and next_symbol.startswith("NT_"):
            # It's a nonterminal - recursively expand
            return _generate(next_symbol, depth + 1)
        
        else:
            # Unknown symbol type - return as-is
            return str(next_symbol)
    
    return _generate(start_symbol, 0)

def generate_molecules(csv_file, start_symbol='NT_1', n_molecules=10, max_depth=50):
    """
    Generate multiple molecules from the cumulative probability matrix.
    
    Args:
        csv_file: Path to CSV file with cumulative probability matrix
        start_symbol: Starting nonterminal
        n_molecules: Number of molecules to generate
        max_depth: Maximum expansion depth
        
    Returns:
        list: Generated molecule strings
    """
    matrix_df = pd.read_csv(csv_file)
    
    molecules = []
    for i in range(n_molecules):
        molecule = generate_random_molecule(matrix_df, start_symbol, max_depth)
        molecules.append(molecule)
    
    return molecules

# Example usage
if __name__ == "__main__":
    csv_file = "cdf_matrix_with_headers.csv" # Path to your CSV file
    
    # Generate molecules
    molecules = generate_molecules(
        csv_file, 
        start_symbol='NT_1',
        n_molecules=10,
        max_depth=50
    )
    
    print("Generated Molecules:")
    print("-" * 80)
    for i, mol in enumerate(molecules, 1):
        print(f"{i}. {mol}")
    
    # Statistics
    print("\n" + "="*80)
    print(f"Total molecules: {len(molecules)}")
    print(f"Average length: {np.mean([len(m) for m in molecules]):.2f}")
    print(f"Min length: {min(len(m) for m in molecules)}")
    print(f"Max length: {max(len(m) for m in molecules)}")