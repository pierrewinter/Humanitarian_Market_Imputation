"""
Created on Wed Nov 07 2018

@author: Analytics Club at ETH internal@analytics-club.org
"""

import itertools
import time
from time import localtime, strftime
from os import path, mkdir, rename
import sys
from sklearn.metrics import (accuracy_score, confusion_matrix, classification_report)
from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import LabelEncoder
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from src.utils.evaluation import plot_confusion_matrix
plt.style.use('ggplot')


def test_model(model, name_model, x_train, y_train, x_test, y_test, details=False,
               normalize=False, weights=None, return_model=False, lib='scikit-learn', fit_params={}):
    """
    Function that does a detailed investigation of a given model. Confusion matrices are generated
    and various metrics are shown.
    Currently supported libraries: 'scikit-learn' (including Pipeline), 'keras'.

    For language classification additional features are implemented and recognized by
    pipelines named steps, if name:
    - 'vect': (CountVectorizer) word counts are displayed for most and least frequent words
    - 'tfidf': (TfidfTransformer) words with highest and lowest TFIDF scores are displayed
    - 'multNB': (MultinomialNB) words with highest and lowest weights are shown

    Parameters
    ----------
    model : object with attributes fit & predict (+ others...)
        The model being tested

    name_model : string
        Name of the model being tested

    x_train : array-like, shape (n_samples, n_features)
        Training vector, where n_samples is the number of samples and
        n_features is the number of features.

    y_train : array-like, shape (n_samples) or (n_samples, n_features)
        Target relative to x_train for classification

    x_test : array-like, shape (n_samples, n_features)
        Training vector, where n_samples is the number of samples and
        n_features is the number of features.

    y_test : array-like, shape (n_samples) or (n_samples, n_features)
        Target relative to x_test for classification

    details : bool
        If True evaluation about every parameter configuration is shown
        default False

    normalize : bool
        Specifies wheter or not confusion matrix is normalized.
        default False

    weights : dict
        weights used in fit method. For example for KerasClassifier
        model.fit(x_train, y_train, class_weight=weights)

    return_model : bool
        model is returned if True
        default False
    lib : string
        specifies which library the model belongs to
        Possible choices are: 'scikit-learn' (default), 'keras'

    fit_params : dict
        fitting parameters for the classifier - only works for lib="keras",
        pass weights via seperate argument, as the class labels need to be encoded otherwise.

    Returns
    -------
    model, if return_model True
    """

    if lib == 'keras':
        le = LabelEncoder()
        y_test_dec = y_test
        y_test = le.fit_transform(y_test)
        y_train_dec = y_train
        y_train = le.transform(y_train)
        # Encode the class label for the weights
        df = pd.DataFrame(weights, index=[0])
        df.columns = le.transform(df.columns)
        class_weights = df.iloc[0].to_dict()
        if weights is not None:
            try:
                model.fit(x_train, y_train, class_weight=class_weights, **fit_params)
            except Exception as e:
                print(e)
                print("You probably face the issue that scikit-learn's fit method does not have"
                      " the attribute class_weight.")
        else:
            model.fit(x_train, y_train, **fit_params)

    else:
        model.fit(x_train, y_train)
    print('############################################# \n model: {} \n'.format(name_model)
          + '#############################################')
    if details and hasattr(model, 'named_steps'):
        print('the list of steps and parameters in the pipeline\n')
        for k, v in model.named_steps.items():
            print('{}: {}\n'.format(k, v))

    if lib == 'scikit-learn':
        y_pred = model.predict(x_test)
        y_pred_train = model.predict(x_train)
    elif lib == 'keras':
        y_pred = model.predict_classes(x_test)
        y_pred_train = model.predict_classes(x_train)
    else:
        print("No library recognized.")
        exit()

    # make sure we work with the correct encoding
    if lib == 'keras':
        y_pred_dec = le.inverse_transform(y_pred)
        y_pred_train_dec = le.inverse_transform(y_pred_train)
        model_classes = le.classes_
    elif lib == 'scikit-learn':
        y_pred_dec = y_pred
        y_pred_train_dec = y_pred_train
        y_train_dec = y_train
        y_test_dec = y_test
        model_classes = model.classes_

    # print accuracy
    print('accuracy on test set: \n {} % \n'.format(accuracy_score(y_test_dec, y_pred_dec)))
    print('accuracy on train set: \n {} % \n'.format(accuracy_score(y_train_dec, y_pred_train_dec)))

    # print report
    rep = classification_report(y_test_dec, y_pred_dec)
    print('classification report: \n {} \n '.format(rep))

    cm = confusion_matrix(y_test_dec, y_pred_dec, labels=model_classes)
    if details:
        print('confusion matrix: \n {} \n'.format(cm))

        print('Actual labels:')
        for i, j in zip(np.sum(cm, axis=1), model_classes):
            print(' ', j, i)
        print('')
        print('Predicted labels:')
        for i, j in zip(np.sum(cm, axis=0), model_classes):
            print(' ', j, i)
        print('')

    # Plot non-normalized confusion matrix
    plt.figure()
    plt.figure(figsize=(12, 12))
    plot_confusion_matrix(cm, classes=model_classes,
                          title='Confusion matrix', normalize=normalize)
    plt.show();  # ";" to avoid avoid double plot display in Jupyter notebook

    if details:
        # print the lenght of the vocabulary
        has_index = False
        if hasattr(model, 'named_steps'):
            if 'vect' in model.named_steps.keys():

                # '.vocabulary_': dictionary item (word) and index 'world': index
                # '.get_feature_names()': list of word from (vocabulary)
                voc = model.named_steps['vect'].vocabulary_
                voc_list = sorted(voc.items(), key=lambda kv: kv[1], reverse=True)
                print('length of the vocabulary vector : \n{} {} '
                      '\n'.format(len(voc), len(model.named_steps['vect'].get_feature_names())))

                # looking at the word occurency after CountVectorizer
                vect_fit = model.named_steps['vect'].transform(x_test)
                counts = np.asarray(vect_fit.sum(axis=0)).ravel().tolist()
                df_counts = pd.DataFrame({'term': model.named_steps['vect'].get_feature_names(), 'count': counts})
                df_counts.sort_values(by='count', ascending=False, inplace=True)
                print(df_counts.head(30))
                print(df_counts.tail(10))
                print('')
                n = 0
                for i in voc_list:
                    n += 1
                    print('    ', i)
                    if n > 20:
                        break

                print('more frequent words: \n{} \n'.format(voc_list[0:20]))
                print('less frequent words: \n{} \n'.format(voc_list[-20:-1]))
                # print('longest word: \n{} \n'.format(max(voc, key=len)))
                # print('shortest word: \n{} \n'.format(min(voc, key=len)))

                index = model.named_steps['vect'].get_feature_names()
                has_index = True

            # print the tfidf values
            if 'tfidf' in model.named_steps.keys():
                tfidf_value = model.named_steps['tfidf'].idf_
                # print('model\'s methods: {}\n'.format(dir(model.named_steps['tfidf'])))

                if has_index:
                    # looking at the word occurency after CountVectorizer
                    tfidf_fit = model.named_steps['tfidf'].transform(vect_fit)
                    tfidf = np.asarray(tfidf_fit.mean(axis=0)).ravel().tolist()
                    df_tfidf = pd.DataFrame({'term': model.named_steps['vect'].get_feature_names(), 'tfidf': tfidf})
                    df_tfidf.sort_values(by='tfidf', ascending=False, inplace=True)
                    print(df_tfidf.head(20))
                    print(df_tfidf.tail(20))
                    print('')

                    tfidf_series = pd.Series(data=tfidf_value, index=index)
                    print('IDF:')
                    print('Smallest idf:\n{}'.format(tfidf_series.nsmallest(20).index.values.tolist()))
                    print('{} \n'.format(tfidf_series.nsmallest(20).values.tolist()))
                    print('Largest idf:\n{}'.format(tfidf_series.nlargest(20).index.values.tolist()))
                    print('{} \n'.format(tfidf_series.nlargest(20).values.tolist()))

            # print the parameters from the model
            if 'multNB' in model.named_steps.keys():
                values = model.named_steps['multNB'].coef_[0]

                if has_index:
                    features_series = pd.Series(data=values, index=index)
                    print('Model\'s parameters:')
                    print('Smallest coeff:\n{}'.format(features_series.nsmallest(20).index.values.tolist()))
                    print('{} \n'.format(features_series.nsmallest(20).values.tolist()))
                    print('Largest coeff:\n{}'.format(features_series.nlargest(20).index.values.tolist()))
                    print('{} \n'.format(features_series.nlargest(20).values.tolist()))

    # to find the list of label
    # model_classes

    # to find the model and attributes
    # print('model\'s attributes: {}\n'.format(model.__dict__))

    # to find all methods
    # print('model\'s methods: {}\n'.format(dir(model)))
    # dir(model)
    print('')
    if return_model:
        return model


def cross_validation(pipeline, name, param_grid, x, y, folds=3, refit=True, n_jobs=1,
                     visualize=False, details=False, fit_params={}, save=False):
    """
    Function that performs a gridsearchCV and visualizes the results. Results may be plotted and/or saved
    to a csv file.

    Parameters
    ----------
    pipeline : pipeline object
        Model being tested.

    name : string
        Name of the model being tested

    param_grid : dict
        dict of parameter being tested

    x : array-like, shape (n_samples, n_features)
        Training vector, where n_samples is the number of samples and
        n_features is the number of features.

    y : array-like, shape (n_samples) or (n_samples, n_features)
        Target relative to x for classification

    folds : int, optional
        number of cross validation folds used
        default: 3

    refit : bool
        default: True

    n_jobs : int, optional
        number of kernels used for computation
        default: 1

    visualize : bool, optional
        if True the cross validation results are plotted.
        Plotting doesn't work for nested lists as parameters
        default: False

    details : bool, optional
        wheter or not to display results for all evaluations
        default: False

    fit_params : dict, optional
        fitting parameters for method fit

    save : bool, optional
        wheter or not to save the cv results in a .csv file
        default: False

    Returns
    -------

    """
    # The following statement checks wheter or not the file is writeable. This helps to prevent losing
    # reuslts from long calculations.
    if save:
        if path.isdir("./scores/{}".format(name)):
            if path.exists("./scores/{}/{}.csv".format(name, name)):
                try:
                    rename("./scores/{}/{}.csv".format(name, name),
                           "./scores/{}/tempfile.csv".format(name))

                    rename("./scores/{}/tempfile.csv".format(name),
                           "./scores/{}/{}.csv".format(name, name))
                except OSError:
                    print("Close the .csv file, otherwhise new results can't be saved.")
                    sys.exit()

    currenttime = time.time()
    print('Grid Cross Validation for the model: {}'.format(name))
    print('with parameters: \n' + '\n'.join('{}: {}'.format(k, v) for k, v in param_grid.items()))
    print('Number of Folds: {}'.format(folds))
    models = GridSearchCV(pipeline, param_grid, cv=folds, refit=refit, n_jobs=n_jobs,
                          return_train_score=True)
    models.fit(x, y, **fit_params)
    overview = models.cv_results_

    if details:
        for attempt in range(len(overview['mean_fit_time'])):
            print('##################################\n'
                  'Attempt {}\n'
                  '##################################\n'
                  'Paramters:'.format(attempt))
            for param in param_grid:
                param_name = 'param_' + str(param)
                print('{}: {}'.format(param, overview[param_name][attempt]))

            print('\n'
                  'Scores:\n'
                  'Mean test score: {}\n'
                  'mean train score: {}\n \n'.format(overview['mean_test_score'][attempt],
                                                     overview['mean_train_score'][attempt]))

    if visualize:
        scores = pd.DataFrame(columns=param_grid)
        for param in param_grid:
            scores[param] = models.cv_results_['param_' + str(param)]
        scores['mean_score'] = models.cv_results_['mean_test_score']
        scores['std'] = models.cv_results_['std_test_score']

        for param_eval in param_grid:
            plot_values = []
            iterables = []
            fig, ax = plt.subplots()
            for param in param_grid:
                if param != param_eval:
                    iterables.append(param_grid[param])

            for t in itertools.product(*iterables):
                index = 0
                label = ''
                df = scores.copy()
                for param in param_grid:
                    if param != param_eval:
                        df = df[df[param] == t[index]]
                        label = label + '{} = {} '.format(param, t[index])
                        index += 1
                plot_values.append([df])
                ax.errorbar(df[param_eval], df['mean_score'], yerr=df['std'], fmt='.--', label=label)
            ax.set(xlabel=param_eval, ylabel='mean score',
                   title='Analysis of {}'.format(param_eval))
            ax.grid(True)
            plt.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
            fig.tight_layout(rect=[0, 0, 2, 1])
            plt.show()
            if save:
                if not path.isdir("./scores/{}".format(name)):
                    mkdir("./scores/{}".format(name))
                if not path.isdir("./scores/{}/figures".format(name)):
                    mkdir("./scores/{}/figures".format(name))
                fig.savefig("./scores/{}/figures/{}-{}-{}.pdf".format(name, name, param_eval,
                                                                      strftime("%Y-%m-%d_%H-%M", localtime())),
                            bbox_inches='tight')

    if save:
        summary = create_summary(models.cv_results_, folds, param_grid, pipeline.named_steps)
        if not path.exists("./scores/{}/{}.csv".format(name, name)):
            summary.to_csv("./scores/{}/{}.csv".format(name, name), header=True, index=False, sep=';')
        else:
            df = pd.read_csv("./scores/{}/{}.csv".format(name, name), sep=';')
            summary = pd.concat([df, summary])
            summary.to_csv("./scores/{}/{}.csv".format(name, name), header=True, index=False, sep=';')

    print('\n'
          'Best estimator: {}\n'
          'Best score: {}\n'.format(models.best_estimator_, models.best_score_))
    print('Best parameters:\n' + ' \n'.join('{}: {}'.format(k, v) for k, v in models.best_params_.items()))
    print('Time needed: {}s'.format(time.time() - currenttime))


def create_summary(cv_results, folds, params, steps):
    """
    Function that creates the DataFrame containing the information obtained by the gridsearchCV that
    are saved to the csv file.

    Parameters
    ----------
    cv_results :

    folds :

    params :

    steps :

    Returns
    -------
    summary
    """

    df = pd.DataFrame()
    df['test_score'] = cv_results['mean_test_score']
    df['std'] = cv_results['std_test_score']
    df['train_score'] = cv_results['mean_train_score']
    df['cv_folds'] = np.ones(len(df['test_score'])) * folds
    for param in params:
        df[param] = cv_results["param_{}".format(param)]
    df['date'] = strftime("%Y.%m.%d %H:%M", localtime())
    for step in steps:
        df[step] = steps[step]

    return df
