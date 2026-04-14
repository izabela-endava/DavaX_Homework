from dotenv import load_dotenv
from rag import load_books, add_books_to_db
from tools import build_book_dict
from chatbot import run_chat

# Load environment variables (API key)
load_dotenv()

# Initialize RAG data (load books and build vector DB + dictionary)
books = load_books("../data/book_summaries.txt")
add_books_to_db(books)
book_dict = build_book_dict(books)

print("Chat started (type 'exit' to stop)\n")

# CLI loop for user interaction
while True:
    user_input = input("You: ")

    # Exit condition
    if user_input.lower() == "exit":
        break

    # Run chatbot logic (RAG + LLM + tool)
    response = run_chat(user_input, book_dict)

    # Display response
    print("\nBot:", response, "\n")