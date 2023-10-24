################################################################################
#                                                                              #
# Kinetica UDF Sum of Squares Example UDF                                      #
# ---------------------------------------------------------------------------- #
# This UDF takes pairs of input & output tables, computing the sum of the      #
# squares of all the columns for each input table and saving the resulting     #
# sums to the first column of the corresponding output table.                  #
#                                                                              #
################################################################################

from itertools import islice
from kinetica_proc import ProcData

# Instantiate a handle to the ProcData() class
proc_data = ProcData()

# For each pair of input & output tables, calculate the sum of squares of input
#    columns and save results to first output table column
for in_table, out_table in zip(proc_data.input_data, proc_data.output_data):

    # Extend the output table's record capacity by the number of records in the input table
    out_table.size = in_table.size

    # Grab a handle to the second column in the output table (the sum column)
    y = out_table[1];

    # For every record in the table...
    for i in range(0, in_table.size):
        # Copy the input IDs in the first column of the input table
        # to the first column of the output table for later association
        out_table[0][i] = in_table[0][i]

    # Loop through the remaining input table columns
    for in_column in islice(in_table, 1, None):
        # For every record value in the column...
        for calc_num in range(0, in_table.size):
            # Add the square of that value to the corresponding output column
            y[calc_num] += in_column[calc_num] ** 2

proc_data.complete()
