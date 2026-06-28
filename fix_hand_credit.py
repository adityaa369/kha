import re

def fix_hand_credit():
    path = 'lib/features/loans/presentation/pages/hand_loan_details_page.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove Interest Rate and Amount from _buildUnifiedStatsCard
    content = re.sub(
        r"final monthlyInterestRate = loan\.interestRate \?\? 0\.0;\s*final monthlyInterestAmount = loan\.amount \* monthlyInterestRate / 100;",
        "",
        content
    )
    content = re.sub(
        r"_GridItem\(\s*label:\s*'Monthly Interest',\s*value:\s*'\$\{monthlyInterestRate\.toStringAsFixed\(1\)\}%',\s*valueColor:\s*config\.primary,\s*\),",
        "",
        content
    )
    content = re.sub(
        r"_GridItem\(\s*label:\s*'Monthly Interest Amount',\s*value:\s*'₹\$\S+',\s*valueColor:\s*config\.primary,\s*\),",
        "",
        content
    )

    # 2. Change Next Interest Due Date to just Next Due Date in _buildSummaryBlock
    content = content.replace("'Next Interest Due Date'", "'Next Due Date'")
    
    # 3. Change Interest Payment Received to Payment Received
    content = content.replace("'Interest Payment Received'", "'Payment Received'")
    
    # 4. Remove 'Interest Schedule' button
    content = re.sub(
        r"OutlinedButton\.icon\(\s*onPressed:\s*\(\)\s*=>\s*_showPaymentScheduleDialog\(context,\s*loan,\s*config\),\s*icon:\s*Icon\(\s*Icons\.calendar_today_outlined,\s*size:\s*12\.sp,\s*color:\s*config\.primary,\s*\),\s*label:\s*Text\(\s*'Interest Schedule',\s*style:\s*TextStyle\(\s*fontSize:\s*10\.sp,\s*fontWeight:\s*FontWeight\.w700,\s*color:\s*config\.primary,\s*\),\s*\),\s*style:\s*OutlinedButton\.styleFrom\(\s*side:\s*BorderSide\(color:\s*config\.primary\),\s*padding:\s*EdgeInsets\.symmetric\(\s*horizontal:\s*12\.w,\s*vertical:\s*8\.h\),\s*shape:\s*RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(8\.r\),\s*\),\s*\),\s*\),",
        "",
        content
    )

    # 5. Remove 'Record Interest Payment' button from _buildLenderActions
    content = re.sub(
        r"Expanded\(\s*child:\s*OutlinedButton\.icon\(\s*onPressed:\s*\(\)\s*=>\s*_showRecordInterestDialog\(context,\s*loan,\s*config\),\s*icon:\s*Icon\(\s*Icons\.percent,\s*size:\s*14\.sp,\s*color:\s*Colors\.green\.shade700,\s*\),\s*label:\s*FittedBox\(\s*fit:\s*BoxFit\.scaleDown,\s*child:\s*Text\(\s*'Record Interest\\nPayment',\s*textAlign:\s*TextAlign\.center,\s*style:\s*TextStyle\(\s*fontSize:\s*9\.sp,\s*fontWeight:\s*FontWeight\.w700,\s*color:\s*Colors\.green\.shade700,\s*height:\s*1\.1,\s*\),\s*\),\s*\),\s*style:\s*OutlinedButton\.styleFrom\(\s*backgroundColor:\s*Colors\.green\.shade50,\s*side:\s*BorderSide\(color:\s*Colors\.green\.shade100\),\s*padding:\s*EdgeInsets\.symmetric\(vertical:\s*10\.h\),\s*shape:\s*RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(12\.r\),\s*\),\s*elevation:\s*0,\s*\),\s*\),\s*\),\s*SizedBox\(width:\s*6\.w\),",
        "",
        content
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_hand_credit()
