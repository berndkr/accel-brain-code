# -*- coding: utf-8 -*-
import numpy as np
cimport numpy as np
from abc import ABCMeta, abstractmethod
ctypedef np.float64_t DOUBLE_t


class ReconstructableModel(metaclass=ABCMeta):
    '''
    The interface of reconstructable model.
    '''

    @abstractmethod
    def learn(self, np.ndarray[DOUBLE_t, ndim=3] observed_arr, np.ndarray target_arr=np.array([])):
        '''
        Learn the observed data points
        for vector representation of the input time-series.

        Override.

        Args:
            observed_arr:    Array like or sparse matrix as the observed data points.
            target_arr:      Array like or sparse matrix as the target data points.
                             To learn as Auto-encoder, this value must be `None` or equivalent to `observed_arr`.
        '''
        raise NotImplementedError()

    @abstractmethod
    def inference(
        self,
        np.ndarray[DOUBLE_t, ndim=3] observed_arr,
        np.ndarray[DOUBLE_t, ndim=2] hidden_activity_arr=None,
        np.ndarray[DOUBLE_t, ndim=2] rnn_activity_arr=None
    ):
        '''
        Inference the feature points to reconstruct the time-series.

        Args:
            observed_arr:           Array like or sparse matrix as the observed data points.
            hidden_activity_arr:    Array like or sparse matrix as the state in hidden layer.
            rnn_activity_arr:       Array like or sparse matrix as the state in RNN.

        Returns:
            Tuple(
                Array like or sparse matrix of reconstructed instances of time-series,
                Array like or sparse matrix of the state in hidden layer,
                Array like or sparse matrix of the state in RNN
            )
        '''
        raise NotImplementedError()

    @abstractmethod
    def get_feature_points(self):
        '''
        Extract feature points.
        
        Returns:
            Array like or sparse matrix of feature points.
        '''
        raise NotImplementedError()

    @abstractmethod
    def hidden_back_propagate(self, np.ndarray[DOUBLE_t, ndim=2] delta_output_arr):
        '''
        Back propagation in hidden layer.
        
        Args:
            delta_output_arr:    Delta.
        
        Returns:
            Tuple(
                `np.ndarray` of Delta, 
                `list` of gradations
            )
        '''
        raise NotImplementedError()
