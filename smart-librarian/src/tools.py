# Convert the list of books into a dictionary for fast lookup
def build_book_dict(books):
    book_dict = {}

    for book in books:
        book_dict[book["title"]] = book["summary"]

    return book_dict

# Retrieve full summary for a given book title
def get_summary_by_title(title: str, book_dict: dict) -> str:
    return book_dict.get(title, "Summary not found.")