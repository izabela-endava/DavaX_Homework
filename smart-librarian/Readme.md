# Smart Librarian

This project implements a **Smart Librarian chatbot** that recommends books based on user interests using:

* **RAG (Retrieval-Augmented Generation)** with ChromaDB
* **OpenAI GPT models**
* **Function calling (tool usage)** for retrieving full book summaries
* **Optional image generation** for creating visual book cover illustrations

The chatbot can:

* recommend books based on themes or preferences
* answer questions about specific books (e.g., *"What is 1984?"*)
* return a detailed summary using a tool
* generate a representative image for the recommended book

---

## How It Works

The system has the following workflow:

1. Book summaries are loaded from a local file.
2. Each summary is converted into an embedding using OpenAI.
3. Embeddings are stored in **ChromaDB**.
4. The user sends a query.
5. The system retrieves the most relevant books (RAG).
6. The LLM selects the best match.
7. The LLM calls a tool:  
   `get_summary_by_title(title)`
8. The tool returns the full summary.
9. The LLM generates the final response.
10. The user can generate a **book cover-style image** based on the selected title.

---

## Features

* Semantic search using embeddings
* Multi-candidate retrieval (top 3 results)
* Tool calling for accurate summaries
* Support for:

  * recommendation queries
  * direct book questions (e.g., "What is Dune?")
* Two interfaces:

  * CLI (terminal)
  * Streamlit UI

---

## Technologies

* Python
* OpenAI API (GPT + embeddings + image generation)
* ChromaDB (vector database)
* Streamlit (UI)
* dotenv (environment variables)

---

## Requirements

* Python 3.9+
* OpenAI API key

Install dependencies:

```bash
pip install openai chromadb streamlit python-dotenv
```

---

## Environment Setup

Create a `.env` file in the project root:

```env
OPENAI_API_KEY=your_api_key_here
```

---

## How to Run

###  CLI version

```bash
python main.py
```

---

### Streamlit UI

```bash
streamlit run app.py
```

Then open:

```
http://localhost:8501
```

---

## Example Prompts

* "I want a book about friendship and magic"
* "What do you recommend for someone who loves war stories?"
* "What is 1984?"
* "Recommend me a dystopian novel"

---

## Tool Function

The project uses a local tool:

```python
get_summary_by_title(title: str) -> str
```

This function retrieves the **exact summary** of a book from a dictionary.

---

## RAG Flow Explanation

* RAG retrieves relevant book summaries using embeddings.
* The LLM does **not search directly**, but selects from retrieved results.
* This reduces hallucination and ensures answers are grounded in data.
