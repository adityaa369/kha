import re

filepath = 'lib/features/loans/presentation/pages/create_loan_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Row to Column for Interest
target_interest = r'''                Row\(
                  crossAxisAlignment: CrossAxisAlignment\.start,
                  children: \[
                    Expanded\(
                      child: (KhaataTextField\([\s\S]*?label: 'Interest Amount'[\s\S]*?\),)
                    \),
                    SizedBox\(width: 16\.w\),
                    Expanded\(
                      child: (KhaataTextField\([\s\S]*?label: 'Rate of Interest'[\s\S]*?\),)
                    \),
                  \],
                \),'''

replacement_interest = r'''                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    \1
                    SizedBox(height: 16.h),
                    \2
                  ],
                ),'''

content = re.sub(target_interest, replacement_interest, content)

# 2. Row to Column for Start Date & End Date
target_dates_end = r'''                Row\(
                  children: \[
                    Expanded\(
                      child: (_DateSelector\([\s\S]*?label: 'Start Date'[\s\S]*?\),)
                    \),
                    SizedBox\(width: 16\.w\),
                    Expanded\(
                      child: (_DateSelector\([\s\S]*?label: 'End Date'[\s\S]*?\),)
                    \),
                  \],
                \),'''

replacement_dates_end = r'''                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    \1
                    SizedBox(height: 16.h),
                    \2
                  ],
                ),'''

content = re.sub(target_dates_end, replacement_dates_end, content)

# 3. Row to Column for Start Date & Due Date
target_dates_due = r'''                Row\(
                  children: \[
                    Expanded\(
                      child: (_DateSelector\([\s\S]*?label: 'Start Date'[\s\S]*?\),)
                    \),
                    SizedBox\(width: 16\.w\),
                    Expanded\(
                      child: (_DateSelector\([\s\S]*?label: 'Due Date'[\s\S]*?\),)
                    \),
                  \],
                \),'''

replacement_dates_due = r'''                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    \1
                    SizedBox(height: 16.h),
                    \2
                  ],
                ),'''

content = re.sub(target_dates_due, replacement_dates_due, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done with Regex replacement")
