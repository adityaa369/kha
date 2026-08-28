with open('lib/data/models/loan_model.dart', 'rb') as f:
    data = f.read()

line2_start = data.find(b"import 'package:equatable")
if line2_start != -1:
    print("Bytes just before import equatable:")
    print(data[line2_start-10:line2_start+20].hex())
