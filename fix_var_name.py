import glob

for file_path in glob.glob('lib/features/loans/presentation/pages/*_loan_details_page.dart'):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content.replace("activeLoan.loanStatus.isFinished", "loan.loanStatus.isFinished")
    new_content = new_content.replace("activeLoan.status.toUpperCase()", "loan.status.toUpperCase()")
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
