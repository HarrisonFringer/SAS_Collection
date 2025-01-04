# -*- coding: utf-8 -*-
"""
Created on Mon Jul 15 14:55:31 2024

@author: harri
"""
import torch
data = [[1,2],[3,4]]
x_data = torch.tensor(data)

x_ones = torch.ones_like(x_data)


x_zeros = torch.zeros_like(x_data)


x_rand = torch.rand_like(x_data, dtype = torch.float)


dims = (3, 4)
rand_tensor = torch.rand(dims, dtype = torch.float)
print(rand_tensor)

torch.is_complex(rand_tensor)
torch.is_floating_point(rand_tensor)
torch.numel(rand_tensor)
torch.set_printoptions(precision = 5)

step_tensor = torch.arange(start = 2, step = 3, end = 17, dtype=torch.int32)

x_step = torch.linspace(-3.14, 3.14, 2000)

y_step = torch.exp(x_step)

ident_tensor = torch.eye(3)

torch.adjoint(rand_tensor)
torch.transpose(rand_tensor, 0, 1)

torch.bernoulli(rand_tensor)

zero_4tens = torch.zeros(dims)
print(f"First column: {zero_4tens[:,0]}")
print(f"First row: {zero_4tens[0]}")
zero_4tens[0,2] = 3

tens_long = torch.cat([zero_4tens,zero_4tens],dim = 1)
tens_wide = torch.cat([zero_4tens,zero_4tens])


tens2_long = torch.transpose(tens_long, 0, 1)
tens_cat = torch.cat([tens2_long,torch.zeros((8,1))], dim = 1)

newdim = (4,6)
torch.select(tens_cat, 1, 2)
pickandchoose = torch.ones(newdim)
pickandchoose[:,0] += 1
pickedandchose = pickandchoose[pickandchoose[:,0] > 2]
pickandchoose
pickedandchose
