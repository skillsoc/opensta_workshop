import re
from tkinter import Tk, Label, Entry, Button, Listbox, Scrollbar, Toplevel, END, filedialog, Text
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np

# Function to extract standard cell names from .lib file
def extract_cell_names(lib_file_path, pattern=None):
    try:
        with open(lib_file_path, 'r') as lib_file:
            content = lib_file.read()
        
        # Use regex to find all standard cell names
        cell_names = re.findall(r'\s+cell\s+\("(.*?)"\)', content)
        
        # Filter cell names based on the pattern if provided
        if pattern:
            cell_names = [name for name in cell_names if re.search(pattern, name)]
        
        return cell_names
    except Exception as e:
        return [f"Error: {str(e)}"]

# Function to extract the timing matrix of a selected cell
def extract_timing_matrix(lib_file_path, cell_name):
    cell_content = []
    timing_content = []
    timingFlag = 0
    cellContent = 0

    try:
        with open(lib_file_path, 'r') as lib_file:
            for line in lib_file:
                if timingFlag:
                    timing_content.append(line)
                    if ")" in line and "values" in timing_content[0]:
                        timingFlag = 0
                        cellContent = 0
                        break
                if cellContent:
                    if re.search(r'timing\s*\(\)\s*\{', line):
                        timingFlag = 1
                if re.search(rf'cell\s+\("{cell_name}"\)', line):
                    cellContent = 1
    except Exception as e:
        print(f"Error: {str(e)}")

    # Extract row indices (index_1), column indices (index_2), and matrix values
    row = []
    column = []
    data = []

    try:
        matrix_data = []
        for i, line in enumerate(timing_content):
            if "index_1" in line:
                row = list(map(float, re.findall(r"[\d\.]+", line)))[1:]  # Remove the first element
            elif "index_2" in line:
                column = list(map(float, re.findall(r"[\d\.]+", line)))[1:]  # Remove the first element
            elif "values" in line:
                matrix_data = timing_content[i:(i + len(row))]
                break
        data = [list(map(float, re.findall(r"[\d\.]+", line))) for line in matrix_data]
    except Exception as e:
        print(f"Error parsing timing content: {str(e)}")

    return row, column, data

# Function to handle file selection and display content
lib_file_path = ""
def select_file():
    global lib_file_path
    lib_file_path = filedialog.askopenfilename(filetypes=[("LIB files", "*.lib"), ("All files", "*.*")])
    if lib_file_path:
        with open(lib_file_path, 'r') as file:
            content = file.read()
        file_content_text.delete(1.0, END)
        file_content_text.insert(END, content)

# Function to extract cell names from the displayed file content
def extract_and_display_cells():
    if not lib_file_path:
        file_content_text.delete(1.0, END)
        file_content_text.insert(END, "Please select a .lib file first.")
        return

    pattern = pattern_entry.get()
    cell_names = extract_cell_names(lib_file_path, pattern if pattern else None)
    cell_listbox.delete(0, END)
    if cell_names:
        for cell in cell_names:
            cell_listbox.insert(END, cell)
    else:
        cell_listbox.insert(END, "No matching standard cell names found.")

# Function to display the timing matrix in a text box and provide a button for a 3D plot
def display_timing_matrix():
    selected_cell = cell_listbox.get(cell_listbox.curselection()) if cell_listbox.curselection() else None
    if not selected_cell:
        return

    row, column, data = extract_timing_matrix(lib_file_path, selected_cell)

    if row and column and data:
        # Create a new window to display the timing matrix
        matrix_window = Toplevel(root)
        matrix_window.title("Timing Matrix")

        result_text = Text(matrix_window, width=80, height=20)
        result_text.pack(padx=10, pady=10)

        result_text.insert(END, "Row Indices (Transition):\n" + ", ".join(map(str, row)) + "\n\n")
        result_text.insert(END, "Column Indices (Output Load):\n" + ", ".join(map(str, column)) + "\n\n")
        result_text.insert(END, "Timing Matrix (values):\n")
        for row_data in data:
            result_text.insert(END, ", ".join(map(str, row_data)) + "\n")

        # Function to show the 3D plot
        def show_3d_plot():
            fig = plt.figure()
            ax = fig.add_subplot(111, projection='3d')

            # Prepare data for plotting
            X, Y = np.meshgrid(column, row)
            Z = np.array(data)

            # Create a surface plot
            surf = ax.plot_surface(X, Y, Z, cmap='viridis')

            # Add labels and title
            ax.set_xlabel('Output Load')
            ax.set_ylabel('Transition')
            ax.set_zlabel('Values')
            ax.set_title(f'Timing Matrix for {selected_cell}')

            # Show the plot
            plt.colorbar(surf)
            plt.show()

        # Button to show 3D plot
        Button(matrix_window, text="Show 3D Plot", command=show_3d_plot).pack(pady=5)

        # Add a close button to close the matrix window
        Button(matrix_window, text="Close", command=matrix_window.destroy).pack(pady=10)

# Close the main application
def close_main_app():
    root.destroy()

# GUI Setup
root = Tk()
root.title(".lib File Viewer and Standard Cell Extractor")

# Button to select file and display content
Button(root, text="Select .lib File", command=select_file).grid(row=0, column=0, pady=10)

# Text box to display file content
file_content_text = Text(root, width=80, height=15)
file_content_text.grid(row=1, column=0, columnspan=2, padx=10, pady=10)

# Label and entry for pattern
Label(root, text="Enter Pattern (optional):").grid(row=2, column=0, padx=10, pady=10)
pattern_entry = Entry(root, width=50)
pattern_entry.grid(row=2, column=1, padx=10, pady=10)

# Button to extract cell names
Button(root, text="Extract Cell Names", command=extract_and_display_cells).grid(row=3, column=0, columnspan=2, pady=10)

# Listbox with scrollbar to display results
scrollbar = Scrollbar(root)
scrollbar.grid(row=4, column=2, sticky="ns")
cell_listbox = Listbox(root, width=60, height=10, yscrollcommand=scrollbar.set)
cell_listbox.grid(row=4, column=0, columnspan=2, padx=10, pady=10)
scrollbar.config(command=cell_listbox.yview)

# Button to display timing matrix of selected cell
Button(root, text="Display Timing Matrix", command=display_timing_matrix).grid(row=5, column=0, columnspan=1, pady=10)

# Close button for the main application
Button(root, text="Close Application", command=close_main_app).grid(row=5, column=1, columnspan=1, pady=10)

# Run the GUI loop
root.mainloop()

