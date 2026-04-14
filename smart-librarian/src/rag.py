import chromadb
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables (API key)
load_dotenv()

# Initialize OpenAI client
client = OpenAI()

# Initialize ChromaDB and create collection
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection(name="books")


def load_books(file_path):
    # Read raw book summaries file
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Split content by book entries
    books = content.split("## Title:")
    parsed_books = []

    for book in books:
        if book.strip() == "":
            continue

        # Extract title and summary
        lines = book.strip().split("\n")
        title = lines[0].strip()
        summary = " ".join(lines[1:]).strip()

        # Store structured data
        parsed_books.append({
            "title": title,
            "summary": summary
        })

    return parsed_books


def add_books_to_db(books):
    if collection.count() > 0:
        return
    # Add each book to vector database with embeddings
    for i, book in enumerate(books):
        # Generate embedding from summary text
        embedding = client.embeddings.create(
            model="text-embedding-3-small",
            input=book["summary"]
        ).data[0].embedding

        # Store document, embedding, and metadata
        collection.add(
            documents=[book["summary"]],
            embeddings=[embedding],
            ids=[str(i)],
            metadatas=[{"title": book["title"]}]
        )


def search_books(query):
    # Convert user query into embedding
    embedding = client.embeddings.create(
        model="text-embedding-3-small",
        input=query
    ).data[0].embedding

    # Perform semantic search (top 3 matches)
    results = collection.query(
        query_embeddings=[embedding],
        n_results=3
    )

    return results