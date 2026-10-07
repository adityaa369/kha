import sys

filepath = 'lib/features/loans/presentation/pages/create_loan_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target1 = """              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Customer Name *',
                      hint: 'Enter customer name',
                      controller: _borrowerNameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (val) => val == null || val.trim().length < 3
                          ? 'Name is required (min 3 chars)'
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: KhaataTextField(
                      label: 'Mobile Number',
                      hint: 'Enter mobile number',
                      controller: _mobileController,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (val) => val == null || val.length != 10
                          ? 'Enter valid 10-digit number'
                          : null,
                    ),
                  ),
                ],
              ),"""

replacement1 = """              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KhaataTextField(
                    label: 'Customer Name *',
                    hint: 'Enter customer name',
                    controller: _borrowerNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (val) => val == null || val.trim().length < 3
                        ? 'Name is required (min 3 chars)'
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  KhaataTextField(
                    label: 'Mobile Number',
                    hint: 'Enter mobile number',
                    controller: _mobileController,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (val) => val == null || val.length != 10
                        ? 'Enter valid 10-digit number'
                        : null,
                  ),
                ],
              ),"""

target2 = """              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Bill Amount *',
                      hint: 'Enter bill amount',
                      controller: _amountController,
                      prefixIcon: const Icon(Icons.currency_rupee),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) =>
                          val == null ||
                              val.isEmpty ||
                              (double.tryParse(val) ?? 0) <= 0
                          ? 'Enter a valid amount'
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _DateSelector(
                      label: 'Date *',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                  ),
                ],
              ),"""

replacement2 = """              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KhaataTextField(
                    label: 'Bill Amount *',
                    hint: 'Enter bill amount',
                    controller: _amountController,
                    prefixIcon: const Icon(Icons.currency_rupee),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) =>
                        val == null ||
                            val.isEmpty ||
                            (double.tryParse(val) ?? 0) <= 0
                        ? 'Enter a valid amount'
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  _DateSelector(
                    label: 'Date *',
                    date: _startDate,
                    onTap: () => _selectDate(context, isDue: false),
                  ),
                ],
              ),"""

if target1 in content:
    content = content.replace(target1, replacement1)
    print("Replaced target 1")
else:
    print("Target 1 not found")

if target2 in content:
    content = content.replace(target2, replacement2)
    print("Replaced target 2")
else:
    print("Target 2 not found")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
