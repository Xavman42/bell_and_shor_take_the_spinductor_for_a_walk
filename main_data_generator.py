import math
import matplotlib.pyplot as plt
from qiskit import QuantumCircuit, transpile
from qiskit_aer import Aer
import random
import csv

from shors_v2 import factorize

filename = 'csvdata.csv'
f = open(filename, "w+")  # truncate the file
f.close()

# this dictionary is just for storing cumulative data
data_dict = {'00': 0, '01': 0, '10': 0, '11': 0, 'x1': 0, 'x2': 0, 'y1': 0, 'y2': 0, 'z1': 0, 'z2': 0}

shots = 1000  # generate this number of circuits
for i in range(1, shots):
    # In the following, we run a bunch of Bell-style tests.
    # Test details are in this paper: http://lilith.fisica.ufmg.br/~fqii/Mermin-PhysToday85.pdf
    qc = QuantumCircuit(2)  # my quantum circuit has two qubits
    basis1 = random.randint(0, 2)  # pick the basis for qubit 1
    basis2 = random.randint(0, 2)  # pick the basis for qubit 1
    # qc.h(0)  # apply a Hadamard gate
    qc.u(random.random()*2*math.pi, 0, 0, 0)  # choose a random angle for the qubit
    qc.cx(0, 1)  # entangle the qubits
    for j in range(basis1):  # rotate each qubit to measure in desired basis
        qc.u(2*math.pi / 3, 0, 0, 0)
    for j in range(basis2):
        qc.u(2*math.pi / 3, 0, 0, 1)
    qc.measure_all()  # measure the qubits!

    simulator = Aer.get_backend('aer_simulator')  # this is Qiskit stuff I don't worry about
    circ = transpile(qc, simulator)

    result = simulator.run(circ, shots=1).result()
    counts = result.get_counts(circ)
    for key in counts:  # all this is just data formatting
        data_dict[key] = data_dict[key] + counts[key]
        if basis1 == 0:
            data_dict['x1'] = data_dict['x1'] + counts[key]
        if basis2 == 0:
            data_dict['x2'] = data_dict['x2'] + counts[key]
        if basis1 == 1:
            data_dict['y1'] = data_dict['y1'] + counts[key]
        if basis2 == 1:
            data_dict['y2'] = data_dict['y2'] + counts[key]
        if basis1 == 2:
            data_dict['z1'] = data_dict['z1'] + counts[key]
        if basis2 == 2:
            data_dict['z2'] = data_dict['z2'] + counts[key]
    correlation = (data_dict['01'] + data_dict['10'])/(i+1)

    # The factorize function is a classical brute force factorization of the number i
    # Uncomment the following to see the results as they are coming in
    # print([i, *counts.keys(), basis1, basis2, correlation, factorize(i)])
    with open(filename, 'a') as file:
        wr = csv.writer(file, delimiter=';')
        wr.writerow([i, *counts.keys(), basis1, basis2, correlation, factorize(i)])

print(data_dict)
print('correlation percent: ' + str(correlation))

qc.draw("mpl")
plt.show()  # plot the circuit
