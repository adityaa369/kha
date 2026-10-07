import sys

filepath = 'lib/features/loans/presentation/pages/create_loan_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip_count = 0

for i in range(len(lines)):
    if skip_count > 0:
        skip_count -= 1
        continue
    
    line = lines[i]
    if "Row(" in line:
        # Check if this Row has Expanded fields that we want to flatten
        is_form_row = False
        expanded_count = 0
        has_sizedbox = False
        
        # Look ahead up to 50 lines
        lookahead = min(len(lines) - i, 50)
        for j in range(1, lookahead):
            if "Expanded(" in lines[i+j] and ("KhaataTextField(" in lines[i+j+1] or "_DateSelector(" in lines[i+j+1]):
                expanded_count += 1
            if "SizedBox(width: 16.w)" in lines[i+j]:
                has_sizedbox = True
            if "Row(" in lines[i+j]: # Nested row
                break
            if "]," in lines[i+j]:
                if lines[i+j+1].strip() == "),": # End of Row
                    if expanded_count >= 2 and has_sizedbox:
                        is_form_row = True
                    break
        
        if is_form_row:
            # We found a Row with two Expanded text fields. We need to convert it to a Column.
            new_lines.append(line.replace("Row(", "Column("))
            # Now we process the children of this Row, replacing SizedBox(width...) with height...
            # and removing the Expanded() wrappers.
            
            # Since we just want to remove Row and keep children in a Column, 
            # wait, if we keep Expanded inside a Column, it will cause an error because Expanded requires a flex container 
            # and inside a Column with mainAxisSize max it might expand infinitely or if Column has no bounded height it will error!
            # So we MUST remove the Expanded() wrappers.
            
            # Actually, doing this with a generic line-by-line processor is tricky. Let's just do targeted string replacements.
            pass

