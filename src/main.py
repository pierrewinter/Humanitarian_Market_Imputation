"""
Created on Sunday September 29 2019

@author: Analytics Club at ETH internal@analytics-club.org

Example structure of the main file
"""

from src.data_extraction import load_data, save_data, merging, xml2df
from src.preprocessing import text_process, anonymization, clean_up, detect_language


def extract_data(program, mode):
    """

    function to extract data

    """

    print('Starting data extraction ...')
    print('Program {}, mode {}'.format(program, mode))


def preprocess(program, mode):
    """

    function for preprocessing

    """
    print("Doing preprocessing")
    print('Program {}, mode {}'.format(program, mode))


def train(program, mode):
    """

    function to train the model

    """
    print('Program {}, mode {}'.format(program, mode))
    print('Training the model...')


def predict(program, mode):
    """

    function to do predictions

    """
    print('Program {}, mode {}'.format(program, mode))
    print('Do prediction...')
   

def test(program, mode):
    """

    function to do tests

    """
    print('Program {}, mode {}'.format(program, mode))
    print('Doing tests...')
