#!/usr/bin/env python3

import argparse


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--samples', required=True)

    args = parser.parse_args()

    return args.samples


if __name__ == '__main__':
    samples = parse_args()

    with open('primer_usage.csv', 'w') as out:
        for sample in samples.split(', ['):
            info = sample.replace('[', '')
            info = info.replace(']', '')
            info = info.replace(',', '')
            info = info.split()
            if float(info[2]) >= 0.65:
                name = info[0].split(':')[1]
                row = '{},{},{}\\n'.format(name, info[2], 'pass')
                out.write(row)
            else:
                name = info[0].split(':')[1]
                row = '{},{},{}\\n'.format(name, info[2], 'fail')
                out.write(row)
