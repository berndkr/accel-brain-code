# Deep Learning Library: pydbm_mxnet

`pydbm_mxnet` is Python library based on `MXNet` for building restricted boltzmann machine, deep boltzmann machine, and multi-layer neural networks. 

This library is derived from [pydbm](https://github.com/chimera0/accel-brain-code/tree/master/Deep-Learning-by-means-of-Design-Pattern) (Cython version).

## Description

The function of this library is building and modeling restricted boltzmann machine, deep boltzmann machine, and multi-layer neural networks. The models are functionally equivalent to stacked auto-encoder. The main function is the same as dimensions reduction(or pre-training).

### Design thought

In relation to my [Automatic Summarization Library](https://github.com/chimera0/accel-brain-code/tree/master/Automatic-Summarization), it is important for me that the models are functionally equivalent to stacked auto-encoder. The main function I observe is the same as dimensions reduction(or pre-training). But the functional reusability of the models can be not limited to this. These Python Scripts can be considered a kind of *experiment result* to verify effectiveness of object-oriented analysis, object-oriented design, and GoF's design pattern in designing and modeling neural network, deep learning, and [reinforcement-Learning](https://github.com/chimera0/accel-brain-code/tree/master/Reinforcement-Learning).

For instance, [dbm_multi_layer_builder.py](https://github.com/chimera0/accel-brain-code/blob/master/Deep-Learning-by-means-of-Design-Pattern/mxnet/pydbm_mxnet/dbm/builders/dbm_multi_layer_builder.py) is implemented for running the **deep boltzmann machine** to extract so-called feature points. This script is premised on a kind of *builder pattern* for separating the construction of complex **restricted boltzmann machines** from its **graph** representation so that the same construction process can create different representations. Because of common design pattern and polymorphism, the **stacked auto-encoder** in [demo_stacked_auto_encoder.py](https://github.com/chimera0/accel-brain-code/blob/master/Deep-Learning-by-means-of-Design-Pattern/mxnet/demo_stacked_auto_encoder.py) is *functionally equivalent* to **deep boltzmann machine**.

## Documentation

Full documentation is available on [https://code.accel-brain.com/Deep-Learning-by-means-of-Design-Pattern/](https://code.accel-brain.com/Deep-Learning-by-means-of-Design-Pattern/) . This document contains information on functionally reusability, functional scalability and functional extensibility.

## Installation

Install using pip:

```sh
pip install pydbm_mxnet
```

### Source code

The source code is currently hosted on GitHub.

- [accel-brain-code/Deep-Learning-by-means-of-Design-Pattern/mxnet/](https://github.com/chimera0/accel-brain-code/tree/master/Deep-Learning-by-means-of-Design-Pattern/mxnet/)

### Python package index(PyPI)

Installers for the latest released version are available at the Python package index.

- [pydbm_mxnet : Python Package Index](https://pypi.python.org/pypi/pydbm_mxnet)

### Dependencies

- numpy: v1.13.3 or higher.
- mxnet: latest.

## Usecase: Building the deep boltzmann machine for feature extracting.

Import Python and modules.

```python
# The `Client` in Builder Pattern
from pydbm_mxnet.dbm.deep_boltzmann_machine import DeepBoltzmannMachine
# The `Concrete Builder` in Builder Pattern.
from pydbm_mxnet.dbm.builders.dbm_multi_layer_builder import DBMMultiLayerBuilder
# Contrastive Divergence for function approximation.
from pydbm_mxnet.approximation.contrastive_divergence import ContrastiveDivergence
# Logistic Function as activation function.
from pydbm_mxnet.activation.logistic_function import LogisticFunction
# ReLu function as activation function.
from pydbm_mxnet.activation.relu_function import ReLuFunction
# Tanh function as activation function.
from pydbm_mxnet.activation.tanh_function import TanhFunction
```

Instantiate objects and call the method.

```python
dbm = DeepBoltzmannMachine(
    DBMMultiLayerBuilder(),
    # Dimention in visible layer, hidden layer, and second hidden layer.
    [traning_x.shape[1], 10, traning_x.shape[1]],
    [ReLuFunction(), LogisticFunction(), TanhFunction()], # Setting objects for activation function.
    ContrastiveDivergence(), # Setting the object for function approximation.
    0.05, # Setting learning rate.
    0.5 # Setting dropout rate.
)
# Execute learning.
dbm.learn(traning_arr, traning_count=1000)
```

And the feature points can be extracted by this method.

```python
print(dbm.get_feature_point_list(0))
```

## Usecase: Extracting all feature points for dimensions reduction(or pre-training)

Import Python modules.

```python
# `StackedAutoEncoder` is-a `DeepBoltzmannMachine`.
from pydbm_mxnet.dbm.deepboltzmannmachine.stacked_auto_encoder import StackedAutoEncoder
# The `Concrete Builder` in Builder Pattern.
from pydbm_mxnet.dbm.builders.dbm_multi_layer_builder import DBMMultiLayerBuilder
# Contrastive Divergence for function approximation.
from pydbm_mxnet.approximation.contrastive_divergence import ContrastiveDivergence
# Logistic function as activation function.
from pydbm_mxnet.activation.logistic_function import LogisticFunction
```

Instantiate objects and call the method.

```python
dbm = StackedAutoEncoder(
    DBMMultiLayerBuilder(),
    [target_arr.shape[1], 10, target_arr.shape[1]],
    [LogisticFunction(), LogisticFunction(), LogisticFunction()],
    ContrastiveDivergence(),
    0.0005,
    0.25
)

# Execute learning.
dbm.learn(traning_arr, traning_count=1)
```

And the result of dimention reduction can be extracted by this property.

```python
pre_trained_arr = dbm.feature_points_arr
```

If you want to get the pre-training weights, call `get_weight_arr_list` method.

```python
weight_arr_list = dbm.get_weight_arr_list()
```

`weight_arr_list` is the `list` of weights of each links in DBM. `weight_arr_list[0]` is 2-d `np.ndarray` of weights between visible layer and first hidden layer.

### Related PoC

- [Webクローラ型人工知能によるパラドックス探索暴露機能の社会進化論](https://accel-brain.com/social-evolution-of-exploration-and-exposure-of-paradox-by-web-crawling-type-artificial-intelligence/) (Japanese)
- [深層強化学習のベイズ主義的な情報探索に駆動された自然言語処理の意味論](https://accel-brain.com/semantics-of-natural-language-processing-driven-by-bayesian-information-search-by-deep-reinforcement-learning/) (Japanese)
- [ハッカー倫理に準拠した人工知能のアーキテクチャ設計](https://accel-brain.com/architectural-design-of-artificial-intelligence-conforming-to-hacker-ethics/) (Japanese)
    - [プロトタイプの開発：深層強化学習のアーキテクチャ設計](https://accel-brain.com/architectural-design-of-artificial-intelligence-conforming-to-hacker-ethics/5/#i-2)

## Author

- chimera0(RUM)

## Author URI

- http://accel-brain.com/

## License

- GNU General Public License v2.0

## References

- Ackley, D. H., Hinton, G. E., &amp; Sejnowski, T. J. (1985). A learning algorithm for Boltzmann machines. Cognitive science, 9(1), 147-169.
- Hinton, G. E. (2002). Training products of experts by minimizing contrastive divergence. Neural computation, 14(8), 1771-1800.
- Le Roux, N., &amp; Bengio, Y. (2008). Representational power of restricted Boltzmann machines and deep belief networks. Neural computation, 20(6), 1631-1649.
- Salakhutdinov, R., &amp; Hinton, G. E. (2009). Deep boltzmann machines. InInternational conference on artificial intelligence and statistics (pp. 448-455).
