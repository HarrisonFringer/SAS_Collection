# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
import torch
import torch.nn as nn
import math
import matplotlib.pyplot as mpl

x = np.linspace(-math.pi,math.pi, 2000)
y = np.sin(x)

a = np.random.randn()
b = np.random.randn()
c = np.random.randn()
d = np.random.randn()

learning_rate = 1e-6
for t in range(2000):
    y_pred = a + b*x + c*x**2 + d*x**3
    
    loss = np.square(y_pred - y).sum()
    if t % 100 == 99:
        print(t, loss)
        
    grad_y_pred = 2.0 * (y_pred - y)
    grad_a = grad_y_pred.sum()
    grad_b = (grad_y_pred * x).sum()
    grad_c = (grad_y_pred * x**2).sum()
    grad_d = (grad_y_pred * x**3).sum()
    
    a -= learning_rate * grad_a
    b -= learning_rate * grad_b
    c -= learning_rate * grad_c
    d -= learning_rate * grad_d
    
print(f'Result: y = {a} + {b} x + {c} x^2 + {d} x^3')

dtype = torch.float
device = torch.device("cpu")

x2 = torch.linspace(-math.pi, math.pi, 2000, device = device, dtype = dtype)
y2 = torch.sin(x2)

a2 = torch.randn((), device = device, dtype = dtype)
b2 = torch.randn((), device = device, dtype = dtype)
c2 = torch.randn((), device = device, dtype = dtype)
d2 = torch.randn((), device = device, dtype = dtype)


for i in range(2000):
    y2_pred = a + b*x2 + c*x2**2 + d*x2**3
    
    loss2 = (y2_pred - y2).pow(2).sum().item()
    if i % 100 == 99:
        print(t, loss)
    
    grad_y2_pred = 2.0 * (y2_pred - y2)
    grad_a2 = grad_y2_pred.sum()
    grad_b2 = (grad_y2_pred * x).sum()
    grad_c2 = (grad_y2_pred * x **2).sum()
    grad_d2 = (grad_y2_pred * x **3).sum()
    
    a2 -= learning_rate * grad_a2
    b2 -= learning_rate * grad_b2
    c2 -= learning_rate * grad_c2
    d2 -= learning_rate * grad_d2
    
print(f'Result: y = {a2.item()} + {b2.item()}x + {c2.item()}x^2 + {d2.item()}x^3')

##Let's start figuring out this PyTorch Thing##

##Creating a Simple Linear Regression Model utilizing PyTorch##
data = pd.read_csv(r"C:\Users\harri\Downloads\statistics_dataset.csv")

##Confirming that the data read in as intended##
data.head()

##Splitting the data into a training and testing dataset##
X = data[['income']].values
Y = data[['spending_score']].values

Scaler = MinMaxScaler()
X_Scaled = Scaler.fit_transform(X)
Y_Scaled = Scaler.fit_transform(Y)
X_train, X_test, Y_train, Y_test = train_test_split(X_Scaled, Y_Scaled, test_size= .2, random_state = 3)

##Converting the arrays into Tensors, so that they work in PyTorch##
X_TenTrain = torch.tensor(X_train, dtype = torch.float32)
X_TenTest = torch.tensor(X_test, dtype = torch.float32)
Y_TenTest = torch.tensor(Y_test, dtype = torch.float32)
Y_TenTrain = torch.tensor(Y_train, dtype = torch.float32)


class LinearRegressionModel(nn.Module):
    def __init__(self):
        super(LinearRegressionModel, self).__init__()
        self.linear = nn.Linear(1,1)
        
    def forward(self,x):
        return self.linear(x)
    
model = LinearRegressionModel()
criterion = nn.MSELoss()
optimizer = torch.optim.SGD(model.parameters(), lr=.001)

##Setting the number of iterations to test said LinMod##
print(X_TenTrain.dtype)
print(Y_TenTrain.dtype)
iterations = 2000
for i in range(iterations):
    outputs = model(X_TenTrain)
    loss = criterion(outputs,Y_TenTrain)
    
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    
    if (i + 1) % 5 == 0:
        print(f'Iteration [{i + 1}/{iterations}], Loss: {loss.item():.4f}')
        
##Model Evaluation##
model.eval()
with torch.no_grad():
    predictions = model(X_TenTest)
    test_loss = criterion(predictions, Y_TenTest)
    print(f"Test Loss: {test_loss.item():.4f}")
    
##Model Visualization##
graph_predictions = predictions.numpy()

mpl.scatter(X_test, Scaler.inverse_transform(Y_test), label = "Actual", color = "Blue")
mpl.scatter(X_test, Scaler.inverse_transform(graph_predictions), label = "Predicted", color = "Red")
