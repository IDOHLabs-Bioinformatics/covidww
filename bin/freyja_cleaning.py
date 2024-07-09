"""
Created on Mon Mar  4 13:41:54 2024

@author: David Schaeper
"""

import argparse
import os
from datetime import date

import numpy as np
import pandas as pd


def collapsing(pango, proportion):
    """
    This function collapses similar lineage hits from Freyja into one lineage
    and sums their abundances.

    Usage
    ----------
    list = collapsing(lineages, abundances)

    Parameters
    ----------
    pango : list
        List of the reported lineages from Freyja.
    proportion : list
        List of the abundances of from the Freyja reported lineages in order
        corresponding to the lineages list.

    Returns
    -------
    list
        List consisting of two lists, the collapsed Freyja lineages and
        abundances respectively.

    """
    # initialize variables
    down_lineages = ['.'.join(x.split('.')[:-1]) for x in pango]
    matrix = np.zeros([len(pango), len(pango)])
    used = set()
    collapsed = {}

    for i in range(len(down_lineages)):
        row_matches = set()
        for j in range(len(down_lineages)):
            if j in used:
                continue
            else:
                if i == j:
                    matrix[i, j] = 1
                    row_matches.add(j)
                    used.add(j)
                elif pango[i] == down_lineages[j]:
                    matrix[i, j] = 1
                    row_matches.add(j)
                    used.add(j)
                elif down_lineages[i] == pango[j]:
                    matrix[i, j] = 1
                    row_matches.add(j)
                    used.add(j)
                elif down_lineages[i] == down_lineages[j]:
                    matrix[i, j] = 1
                    row_matches.add(j)
                    used.add(j)

        if row_matches:
            collapsed[pango[i]] = (sum([proportion[x] for x in row_matches]))

    return [list(collapsed.keys()), list(collapsed.values())]


def freyja_results(freyja_results_directory):
    """
    This function reads all the Freyja demix results from a directory and
    returns the collapsed results via collapsing() in a dictionary.

    Usage
    ----------
    dictionary = freyja_results(freyja_results_directory)

    Parameters
    ----------
    freyja_results_directory : str
        Path to a directory containing results from Freyja demix.

    Returns
    -------
    results : dictionary
        A dictionary with the sampleID as the key and the value as a list
        containing two lists, the lineages and abundances.

    """
    # initialize variables
    results = {}

    # write all the results to a dictionary with the samples as the key and the
    # information as a list of lists in the value
    for result in os.listdir(freyja_results_directory):
        if result[0] != '.':  # ignore the hidden files
            with open(os.path.join(freyja_results_directory, result)) as file:
                lineages = []
                abundances = []
                lines = file.readlines()
                name = lines[0].strip().split('.variants.tsv')[0]
                tmp_lineages = lines[2].strip().split('\t')[1].split(' ')
                str_abundances = lines[3].strip().split('\t')[1].split(' ')
                tmp_abundances = [float(x) for x in str_abundances]

                # filter out results less than 10%
                for i in range(len(tmp_abundances)):
                    if tmp_abundances[i] >= 0.1:
                        lineages.append(tmp_lineages[i])
                        abundances.append(tmp_abundances[i])

                results[name] = [lineages, abundances]

    return results


def parsing():
    """
    This function parses the command line arguments.

    Returns
    -------
    argparse.Namespace
        The parsed arguments.

    """
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=str, required=True, help='The directory' +
                                                                       'containing the Freyja results.')

    return parser.parse_args()


if __name__ == '__main__':
    args = parsing()
    report = freyja_results(args.input)
    frame = pd.DataFrame(columns=['Sample', 'Lineage', 'Abundance'])

    # write the final results to a file
    for key, value in report.items():
        lineage = report[key][0]
        abundance = report[key][1]
        for k in range(len(lineage)):
            row = [key, lineage[k], abundance[k]]
            frame.loc[len(frame)] = row

    handle = 'wastewater_analysis_' + str(date.today()) + '.csv'
    frame.to_csv(handle, index=False)
