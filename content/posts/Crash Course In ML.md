+++
author = "Fares Ismail"
date = "2019-12-09T10:00:00+00:00"
tags = [
    "Machine Learning",
    "ML",
]
title = "Crash Course in Machine Learning"
+++

I take article requests now... 😛

The following article will be a quick overview of classical machine learning and the different types and algorithms out there.

Don't expect any code implementation or a hands-on lab this is just to provide an overview of the types of machine learning algorithms and when those can be used.

On a high level, we can think of a machine learning model as a black box. One that will take in some input data, do something with that data and then spit out some output data.

``` text
                    +-------------------------+
Input Data ------>  | Machine Learning Model  | ------> Output Data
                    +-------------------------+

```

This black box however needs to be trained. This is where the word `Learning` comes from.

Similarly, on a very high level, Machine learning models can be broken down into two categories: ``Supervised`` and ``Unsupervised``. Those categories relate to how this model will be trained.

---

## Supervised Learning

In supervised machine learning, We rely on a `training dataset` to teach the ML model how to make accurate future predictions. We say that we have a labeled dataset. That is a dataset containing both the input data (features) and for each input data, the corresponding output data (prediction).

Supervised Learning looks like this:

``` text

                    +-------------------------+
Input Data  ----->  |     Machine learning    | ------> Machine Learning
Output Data ----->  |        Algorithm        |             Model
                    +-------------------------+


   Real             +-------------------------+            Real
Input Data ------>  | Machine Learning Model  | ------> Output Data
                    +-------------------------+

```

Here's an example for a more concrete understanding.

Assume this is out training data:

| Name      | Age   | Profession            | Car       | Salary    |
|:---------:|:-----:|:---------------------:|:---------:|:---------:|
| Danny     | 36    | HR Manager            | Mercedes  | 126,000   |
| Eric      | 25    | Software Engineer     | Toyota    | 45,000    |
| Sarah     | 45    | CEO                   | BMW       | 170,000   |
| Emily     | 21    | Art Major             | N/A       | 10,000    |

If I were to hide the last column and ask you to predict who has the highest salary... Intuitively you'd say that that person is most likely in some sort of managerial position, is a bit older in age and drives a nice car... I'm not saying its always the case (Kylie Jenner became the youngest billionaire ever at 21... :man_facepalming:) ok pardon the digression... It's not always the case but it is the case in general...

This is exactly what we'll be doing with our model. We will give it the input data called features, well give it a lot of data (10,000 to 100,000) and for each row of feature, well give the model the correct prediction (in this case the salary). We will then ask our model to learn what makes people have a high salary.

Later on, we will use that trained model to make actual prediction for people whose salaries are truly unknown to us.

But how can we trust our model and more importantly how can we trust its predictions... There are a lot of techniques to validate a trained model, but the simplest is this:

Split the labeled data into two different sets. A training set that we will feed to the machine learning algorithm, and a testing set that we will use to validate the predictions of the models.
Once the model is trained, we will hide the `Salary` Column of the testing set and we will ask the model to predict the salaries of the testing data. Then we will compare the results of the model with our actual results.

---

There are two subcategories in ``Supervised Learning``: `Classification` and `Regression`. Those depend on the nature of the value to be predicted.

### Classification

Like the name indicates, in classification, we class features into a specific category (also called classes). For example, if we're predicting if a certain credit card transaction is fraudulent or not, we'd be training a classification model. More specifically, a two class classification model: A transaction can be `Fraudulent` or it can be `Non Fraudulent`.
If We were predicting if an email is `Spam` or `Personal` or `Business` then we'd also be training a classification model. But this time, it'll be a three class classification model, because an email can fall into one of three categories.

#### Some Classification Algorithms

- Support Vector Machines (SVM)

- Decision Trees

- Logistic Regression (despite its name 😝)

- K Nearest Neighbor (KNN)

- Naive Bayes Classifier

### Regression

Unlike Classification, regression is where we try to predict a continuous value instead of a category.

For example, out previous case with the predictions of salaries is a regression problem. We are not trying to classify people as rich or not, we are attempting to predict the numerical value representing their salaries. Another example can be the prediction of the cost of a house based on X criteria.

#### Some Regression Algorithms

The most well known and easy to understand algorithm is the `Linear Regression`. Its when we try to model the data to a specific trend line. Using the famous: `y= a.X +b`

Other algos include:

- Non Linear Regression

- Ridge Regression

- Lasso Regression

- Elastic Regression

---

## Unsupervised Learning

In unsupervised learning, the dataset is not labeled. The ML algorithm will attempt to find certain patterns or groups in the dataset.
With unsupervised learning, we are also unsure of the expected outcome.

So why is unsupervised learning useful? because sometimes, we simply don't really know what the correct output is. In other times, it can be too costly to label a specific dataset with 10,000 or 100,000 rows... Unsupervised learning is also very useful in anomaly detection, finding the outliers.

Unsupervised learning can be grouped into 3 categories:

- Clustering

- Association Rules

- Dimensionality Reduction

### Clustering

In Clustering models, we attempt to find groups of data points that are similar to one another.

#### Some Clustering Algorithms

- K-Means Clustering

- K-NN Clustering

- Hierarchical Clustering

### Association Rules

I bet you've done one of the following: bought a item off Amazon, watched a YouTube video, binged watched a series on Netflix, listened to a playlist on Spotify...

They all have one thing in common, they all recommend us even more products.

How do they do it?

Humans are inherently predictable. If 5 people watched the same 10 series on Netflix, odds are they have similar taste in series... So if one of those 5 people started watching a new series, we could recommend it to others as well.

Similarly for supermarkets and Amazon... Someone who recently bought a printer will most likely also buy some paper to go with it.

Those are called association rules. We associate product A with product B because we assume that if a person buys product A, he is most likely to also buy product B. Keep in mind that it might not work the other way around: If I recently bought a printer, ill most likely buy paper. But if I recently bought some paper, I might not need a printer to go with them.

From a marketing perspective, association rules are interesting because they're a way to increase sales.

#### Some Association Rules Algorithms

- Apriori Algorithm

- FP Growth Algorithm

### Dimensionality Reduction

From a mathematical perspective, dimensionality reduction is the process of reducing the number of random variables under consideration by obtaining a set of principal variables.

If this doesn't make any sense, its ok... here's a more concrete example:

| Name      | Age   | Profession            | Car       | Salary in $ | Salary in € |
|:---------:|:-----:|:---------------------:|:---------:|:-----------:|:-----------:|
| Danny     | 36    | HR Manager            | Mercedes  | 126,000     |113309.36    |
| Eric      | 25    | Software Engineer     | Toyota    | 45,000      |40467.63     |
| Sarah     | 45    | CEO                   | BMW       | 170,000     |152877.70    |
| Emily     | 21    | Art Major             | N/A       | 10,000      |8992.81      |

There is a linear correlation between the two columns `Salaries in $` and `Salaries in €`. One of the two columns does not bring in any new information and so its just noise in the data.

With Dimensionality Reduction, this type of correlation can be detected and removed.

#### Some Dimensionality Reduction Algorithms

- Principal Component Analysis (PCA)

- Linear Discriminant Analysis (LDA)

- Generalized Discriminant Analysis (GDA)

---
