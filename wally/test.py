import tabulate
table = [["spam",42],["eggs",451],["bacon",0]]
headers = ["item", "qty"]
print tabulate(table, headers, tablefmt="plain")
