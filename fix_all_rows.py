import sys
import re

filepath = 'lib/features/loans/presentation/pages/create_loan_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern for Row containing Expanded(KhaataTextField) or Expanded(_DateSelector)
# We will match the entire Row block.

# 1. Interest Amount & Rate of Interest
target_interest = """                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KhaataTextField(
                        label: 'Interest Amount',
                        hint: 'Enter amount',
                        controller: _amountController,
                        prefixIcon: Container(
                          margin: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.currency_rupee,
                            color: Colors.green.shade700,
                            size: 18.sp,
                          ),
                        ),
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
                      child: KhaataTextField(
                        label: 'Rate of Interest',
                        hint: 'Enter rate',
                        controller: _interestController,
                        prefixIcon: Container(
                          margin: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.percent,
                            color: Colors.green.shade700,
                            size: 18.sp,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) =>
                            val == null ||
                                val.isEmpty ||
                                (double.tryParse(val) ?? 0) <= 0
                            ? 'Enter valid rate'
                            : null,
                      ),
                    ),
                  ],
                ),"""

replacement_interest = """                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KhaataTextField(
                      label: 'Interest Amount',
                      hint: 'Enter amount',
                      controller: _amountController,
                      prefixIcon: Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.currency_rupee,
                          color: Colors.green.shade700,
                          size: 18.sp,
                        ),
                      ),
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
                    KhaataTextField(
                      label: 'Rate of Interest',
                      hint: 'Enter rate',
                      controller: _interestController,
                      prefixIcon: Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.percent,
                          color: Colors.green.shade700,
                          size: 18.sp,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) =>
                          val == null ||
                              val.isEmpty ||
                              (double.tryParse(val) ?? 0) <= 0
                          ? 'Enter valid rate'
                          : null,
                    ),
                  ],
                ),"""

# 2. Start Date & End Date
target_dates_end = """                Row(
                  children: [
                    Expanded(
                      child: _DateSelector(
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () => _selectDate(context, isDue: false),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _DateSelector(
                        label: 'End Date',
                        date: _dueDate,
                        hint: 'Select end date',
                        onTap: () => _selectDate(context, isDue: true),
                      ),
                    ),
                  ],
                ),"""

replacement_dates_end = """                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateSelector(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                    SizedBox(height: 16.h),
                    _DateSelector(
                      label: 'End Date',
                      date: _dueDate,
                      hint: 'Select end date',
                      onTap: () => _selectDate(context, isDue: true),
                    ),
                  ],
                ),"""

# 3. Start Date & Due Date
target_dates_due = """                Row(
                  children: [
                    Expanded(
                      child: _DateSelector(
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () => _selectDate(context, isDue: false),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _DateSelector(
                        label: 'Due Date',
                        date: _dueDate,
                        hint: 'Select due date',
                        onTap: () => _selectDate(context, isDue: true),
                      ),
                    ),
                  ],
                ),"""

replacement_dates_due = """                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateSelector(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                    SizedBox(height: 16.h),
                    _DateSelector(
                      label: 'Due Date',
                      date: _dueDate,
                      hint: 'Select due date',
                      onTap: () => _selectDate(context, isDue: true),
                    ),
                  ],
                ),"""

content = content.replace(target_interest, replacement_interest)
content = content.replace(target_dates_end, replacement_dates_end)
content = content.replace(target_dates_due, replacement_dates_due)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
