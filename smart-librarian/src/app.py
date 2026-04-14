import streamlit as st
from rag import load_books, add_books_to_db
from tools import build_book_dict
from chatbot import run_chat


# Initialize data once and cache it for performance
@st.cache_resource
def init_data():
    # Load book summaries from file
    books = load_books("../data/book_summaries.txt")

    add_books_to_db(books)

    # Create a dictionary
    book_dict = build_book_dict(books)

    return book_dict


# Load cached data
book_dict = init_data()

# UI title
st.title("📚 Book Recommendation Chatbot")

# User input field
user_input = st.text_input("What kind of book are you looking for?")

# Trigger chatbot response
# Get recommendation
if st.button("Get recommendation"):
    if user_input:
        response, title = run_chat(user_input, book_dict)

        st.session_state["response"] = response
        st.session_state["title"] = title
    else:
        st.warning("Please enter a query.")


# Display saved response
if "response" in st.session_state:
    st.write(st.session_state["response"])


# Generate image button
if "title" in st.session_state and st.session_state["title"]:
    if st.button("🖼️ Generate Image"):
        from chatbot import generate_image

        with st.spinner("Generating image..."):
            image_path = generate_image(st.session_state["title"])

        st.image(image_path, caption=st.session_state["title"])