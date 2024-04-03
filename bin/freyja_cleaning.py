"""
Created on Mon Mar  4 13:41:54 2024

@author: David Schaeper
"""

import argparse
import os

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

    joined_lineages = {}
    for i in range(len(down_lineages)):
        # initialize variables for each row
        match1 = []
        match2_i = []
        match2_j = []
        # perform comparisons
        for j in range(len(down_lineages)):
            if down_lineages[i] == down_lineages[j]:
                match1.append(j)
            elif down_lineages[i] == pango[j]:
                match2_i.append(i)
                match2_j.append(j)
        # sum and add lineage based upon the row result
        if len(match1) > 1 and len(match2_j) > 0:
            both = sum([proportion[x] for x in match1]) + sum([proportion[x] for x in match2_j])
            joined_lineages[pango[match2_j[0]]] = both
        elif len(match1) > 1:
            joined_lineages[down_lineages[match1[0]]] = sum([proportion[x] for x in match1])
        elif len(match2_j) > 0:
            both = sum([proportion[x] for x in match2_i]) + sum([proportion[x] for x in match2_j])
            joined_lineages[pango[match2_j[0]]] = both
        else:
            joined_lineages[pango[match1[0]]] = proportion[match1[0]]

    return [list(joined_lineages.keys()), list(joined_lineages.values())]


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
        if result[0] != '.':  # ignore the nextflow files
            with open(os.path.join(freyja_results_directory, result)) as file:
                lines = file.readlines()
                name = lines[0].split('\t')[1].split('_')[0].strip().split('.')[0]
                tmp_lineages = lines[2].strip().split('\t')[1].split(' ')
                str_abundances = lines[3].strip().split('\t')[1].split(' ')
                tmp_abundances = [float(x) for x in str_abundances]

                results[name] = collapsing(tmp_lineages, tmp_abundances)

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
    parser.add_argument('-o', '--output', type=str, help='Optional output name.')

    return parser.parse_args()


if __name__ == '__main__':
    args = parsing()
    report = freyja_results(args.input)
    frame = pd.DataFrame(columns=['Sample', 'Lineage', 'Abundance'])

    # write the final results to a file
    for key, value in report.items():
        lineages = report[key][0]
        abundances = report[key][1]
        for k in range(len(lineages)):
            row = [key, lineages[k], abundances[k]]
            frame.loc[len(frame)] = row

    if args.output:
        frame.to_csv(args.output, index=False)
    else:
        frame.to_csv('combined_freyja_report.csv', index=False)
