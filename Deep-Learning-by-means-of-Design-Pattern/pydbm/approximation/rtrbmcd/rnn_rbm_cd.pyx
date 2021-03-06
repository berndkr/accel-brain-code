# -*- coding: utf-8 -*-
import numpy as np
cimport numpy as np
cimport cython
from pydbm.approximation.rt_rbm_cd import RTRBMCD
ctypedef np.float64_t DOUBLE_t


class RNNRBMCD(RTRBMCD):
    '''
    Recurrent Neural Network Restricted Boltzmann Machines(RNN-RBM)
    based on Contrastive Divergence.

    Conceptually, the positive phase is to the negative phase what waking is to sleeping.

    Parameters:
        graph.weights_arr:                      $W$ (Connection between v^{(t)} and h^{(t)})
        graph.visible_bias_arr:                 $b_v$ (Bias in visible layer)
        graph.hidden_bias_arr:                  $b_h$ (Bias in hidden layer)
        graph.rnn_hidden_weights_arr:           $W'$ (Connection between h^{(t-1)} and b_h^{(t)})
        graph.rnn_visible_weights_arr:          $W''$ (Connection between h^{(t-1)} and b_v^{(t)})
        graph.hat_hidden_activity_arr:          $\hat{h}^{(t)}$ (RNN with hidden units)
        graph.pre_hidden_activity_arr_list:     $\hat{h}^{(t)} \ (t = 0, 1, ...)$
        graph.v_hat_weights_arr:                $W_2$ (Connection between v^{(t)} and \hat{h}^{(t)})
        graph.hat_weights_arr:                  $W_3$ (Connection between \hat{h}^{(t-1)} and \hat{h}^{(t)})
        graph.rnn_hidden_bias_arr:              $b_{\hat{h}^{(t)}}$ (Bias of RNN hidden layers.)

        $$\hat{h}^{(t)} = \sig (W_2 v^{(t)} + W_3 \hat{h}^{(t-1)} + b_{\hat{h}})
    '''

    def rnn_learn(self, np.ndarray[DOUBLE_t, ndim=2] observed_data_arr):
        '''
        Learning for RNN.

        Args:
            observed_data_list:      observed data points.
        '''
        self.graph.visible_activity_arr = observed_data_arr.copy()

        if self.graph.pre_hidden_activity_arr.shape[0] == 0:
            return
        if self.graph.hat_hidden_activity_arr.shape[0] == 0:
            return

        cdef np.ndarray[DOUBLE_t, ndim=2] v_link_value_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] h_link_value_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] link_value_arr

        v_link_value_arr = np.dot(
            self.graph.visible_activity_arr,
            self.graph.v_hat_weights_arr
        )
        h_link_value_arr = np.dot(
            self.graph.pre_hidden_activity_arr,
            self.graph.hat_weights_arr
        )
        link_value_arr = v_link_value_arr + h_link_value_arr
        link_value_arr += self.graph.rnn_hidden_bias_arr

        self.graph.hat_hidden_activity_arr = self.graph.rnn_activating_function.activate(
            link_value_arr
        )
        
        super().rnn_learn(observed_data_arr)
        
        self.graph.visible_diff_bias_arr += self.graph.visible_bias_arr
        self.graph.hidden_diff_bias_arr += self.graph.hidden_bias_arr

    def memorize_activity(
        self,
        np.ndarray[DOUBLE_t, ndim=2] observed_data_arr,
        np.ndarray[DOUBLE_t, ndim=2] negative_visible_activity_arr
    ):
        '''
        Memorize activity.
        
        Override.

        Args:
            observed_data_arr:                Observed data points in positive phase.
            negative_visible_activity_arr:    visible acitivty in negative phase.
        '''
        if self.graph.pre_hidden_activity_arr.shape[0] == 0 or self.graph.hat_hidden_activity_arr.shape[0] == 0:
            super().memorize_activity(observed_data_arr, negative_visible_activity_arr)
            return

        self.graph.pre_hidden_activity_arr_list.append(self.graph.hat_hidden_activity_arr)

        self.graph.diff_visible_bias_arr_list.append(observed_data_arr - negative_visible_activity_arr)

        cdef np.ndarray[DOUBLE_t, ndim=2] visible_step_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] link_value_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] rnn_step_activity_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] rnn_negative_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] rnn_step_weight_arr
        cdef np.ndarray[DOUBLE_t, ndim=2] rnn_negative_weight_arr

        visible_step_arr = self.graph.visible_activity_arr + self.graph.visible_diff_bias_arr
        rnn_step_activity_arr = self.graph.rnn_activating_function.activate(
            np.dot(
                visible_step_arr,
                self.graph.weights_arr
            ) - self.graph.hidden_bias_arr
        )
        
        rnn_negative_arr = self.graph.rnn_activating_function.activate(
            np.dot(
                self.graph.visible_activity_arr,
                self.graph.weights_arr
            ) - self.graph.hidden_bias_arr
        )
        self.graph.diff_hidden_bias_arr_list.append(rnn_step_activity_arr - rnn_negative_arr)

        rnn_step_weight_arr = np.dot(
            rnn_step_activity_arr.T,
            visible_step_arr
        )
        
        rnn_negative_weight_arr = np.dot(
            rnn_negative_arr.T,
            self.graph.visible_activity_arr
        )

        self.graph.diff_weights_arr += (rnn_step_weight_arr - rnn_negative_weight_arr).T
        self.graph.diff_rnn_hidden_weights_arr += np.dot(
            (rnn_step_activity_arr - rnn_negative_arr).T,
            self.graph.pre_hidden_activity_arr
        )

        super().memorize_activity(observed_data_arr, negative_visible_activity_arr)

    def back_propagation(self):
        '''
        Details of the backpropagation through time algorithm.
        
        Override.
        '''
        diff_rnn_hidden_bias_arr = None
        diff_hat_weights_arr = None
        diff_v_hat_weights_arr = None

        hat_list = self.graph.pre_hidden_activity_arr_list[::-1]
        diff_v_b_list = self.graph.diff_visible_bias_arr_list[::-1]
        diff_h_b_list = self.graph.diff_hidden_bias_arr_list[::-1]

        for t in range(len(hat_list) - 1):
            hat_diff = np.dot(
                ((hat_list[t] - hat_list[t+1]) * hat_list[t] * (1 - hat_list[t+1])),
                self.graph.hat_weights_arr
            )
            hat_diff += np.dot(
                diff_h_b_list[t+1],
                self.graph.rnn_hidden_weights_arr
            )
            hat_diff += np.dot(
                diff_v_b_list[t+1],
                self.graph.rnn_visible_weights_arr
            )

            if t == 0:
                self.graph.hat_hidden_activity_arr += hat_diff

            diff = hat_diff * self.graph.hat_hidden_activity_arr * (1 - self.graph.hat_hidden_activity_arr)
            if diff_rnn_hidden_bias_arr is None:
                diff_rnn_hidden_bias_arr = diff
            else:
                diff_rnn_hidden_bias_arr += diff

            diff = np.dot(
                (hat_diff * self.graph.hat_hidden_activity_arr * (1 - self.graph.hat_hidden_activity_arr)).T,
                self.graph.pre_hidden_activity_arr
            )
            
            if diff_hat_weights_arr is None:
                diff_hat_weights_arr = diff
            else:
                diff_hat_weights_arr += diff
            
            diff = np.dot(
                (hat_diff * self.graph.hat_hidden_activity_arr * (1 - self.graph.hat_hidden_activity_arr)).T, 
                self.graph.visible_activity_arr
            )

            diff = diff.T
            if diff_v_hat_weights_arr is None:
                diff_v_hat_weights_arr = diff
            else:
                diff_v_hat_weights_arr += diff

        delta_rnn_visible_weight_arr = np.dot(
            self.graph.visible_diff_bias_arr.reshape(-1, 1),
            np.nansum(self.graph.pre_hidden_activity_arr, axis=0).reshape(-1, 1).T
        )

        params_list = self.opt_params.optimize(
            params_list=[
                self.graph.visible_bias_arr,
                self.graph.hidden_bias_arr,
                self.graph.weights_arr,
                self.graph.rnn_hidden_weights_arr,
                self.graph.rnn_visible_weights_arr,
                self.graph.rnn_hidden_bias_arr,
                self.graph.hat_weights_arr,
                self.graph.v_hat_weights_arr
            ],
            grads_list=[
                self.graph.visible_diff_bias_arr,
                self.graph.hidden_diff_bias_arr,
                self.graph.diff_weights_arr,
                self.graph.diff_rnn_hidden_weights_arr,
                delta_rnn_visible_weight_arr,
                diff_rnn_hidden_bias_arr,
                diff_hat_weights_arr,
                diff_v_hat_weights_arr
            ],
            learning_rate=self.learning_rate
        )
        self.graph.visible_bias_arr = params_list[0]
        self.graph.hidden_bias_arr = params_list[1]
        self.graph.weights_arr = params_list[2]
        self.graph.rnn_hidden_weights_arr = params_list[3]
        self.graph.rnn_visible_weights_arr = params_list[4]
        self.graph.rnn_hidden_bias_arr = params_list[5]
        self.graph.hat_weights_arr = params_list[6]
        self.graph.v_hat_weights_arr = params_list[7]

        self.graph.visible_diff_bias_arr = np.zeros(self.graph.visible_bias_arr.shape)
        self.graph.hidden_diff_bias_arr = np.zeros(self.graph.hidden_bias_arr.shape)
        self.graph.diff_weights_arr = np.zeros_like(self.graph.weights_arr, dtype=np.float64)
        self.graph.diff_rnn_hidden_weights_arr = np.zeros_like(self.graph.diff_rnn_hidden_weights_arr, dtype=np.float64)
        self.graph.diff_visible_bias_arr_list = []
        self.graph.diff_hidden_bias_arr_list = []
        self.graph.diff_weights_arr_list = []
        self.graph.diff_rnn_hidden_weights_arr_list = []
        self.graph.pre_hidden_activity_arr_list = []
