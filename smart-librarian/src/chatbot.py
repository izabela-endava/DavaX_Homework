from openai import OpenAI
import json
from rag import search_books
from tools import get_summary_by_title
import base64

# Initialize OpenAI client
client = OpenAI()

# Instruction for recommendation flow (RAG + tool)
recommendation_instruction = """
You are a book recommendation assistant.

The system retrieved 3 candidate books.

You MUST:
- Choose ONLY ONE book from the provided list
- Recommend ONLY that book
- DO NOT invent new books
- DO NOT use books outside the list
- give a short reason why it's a good recommendation
- ALWAYS call the function get_summary_by_title

IMPORTANT:
- You must pick the best match from the list
"""

# Instruction for direct book questions
book_question_instruction = """
You are a book assistant.

The user is asking about a specific book.

You MUST:
- briefly explain what the book is
- call the function get_summary_by_title
- DO NOT recommend other books
"""

# Final response formatting (used after tool execution)
final_instruction = """
You are a friendly book assistant.

You MUST:
- mention the book title
- give a natural, conversational explanation (1-2 sentences)
- then show the summary

Format:
<text>

summary: <summary text>

IMPORTANT:
- DO NOT modify the summary
"""

# Tool definition for retrieving summaries
tools = [
    {
        "type": "function",
        "name": "get_summary_by_title",
        "description": "Get full book summary by exact title",
        "parameters": {
            "type": "object",
            "properties": {
                "title": {"type": "string"}
            },
            "required": ["title"],
            "additionalProperties": False
        }
    }
]

client = OpenAI()

# Generate a book cover-style image for a given title using OpenAI image generation
def generate_image(title: str):
    try:
        result = client.images.generate(
            model="gpt-image-1",
            prompt=f"A minimal, artistic book cover illustration inspired by '{title}', safe and neutral",
            size="1024x1536"
        )

        image_base64 = result.data[0].b64_json

        file_path = "cover.png"

        with open(file_path, "wb") as f:
            f.write(base64.b64decode(image_base64))

        return file_path

    except Exception:
        return None

# Check if user input is a recommendation request
def is_valid_request(user_input: str) -> bool:
    response = client.responses.create(
        model="gpt-4.1-mini",
        input=f"Is this a request for a book recommendation? Answer only YES or NO.\n\n{user_input}"
    )

    answer = response.output[0].content[0].text.strip().lower()
    return "yes" in answer


# Detect if user is asking about a specific book
def detect_book_intent(user_input: str, book_dict: dict) -> str | None:
    response = client.responses.create(
        model="gpt-4.1-mini",
        input=f"""
User message: "{user_input}"

Available books:
{list(book_dict.keys())}

If the user is asking ABOUT a specific book from the list, return ONLY the exact title.
If not, return NONE.
"""
    )

    answer = response.output[0].content[0].text.strip().replace(".", "").strip()

    for title in book_dict:
        if title.lower() in answer.lower():
            return title

    return None


def run_chat(user_input, book_dict):

    # 1. Check if user asks about a specific book
    book_title = detect_book_intent(user_input, book_dict)

    if book_title:
        # Prepare input for LLM
        input_data = [
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": f"User request: {user_input}"},
                    {"type": "input_text", "text": f"Book: {book_title}"}
                ]
            }
        ]

        # First call: LLM decides to call tool
        response = client.responses.create(
            model="gpt-4.1-mini",
            instructions=book_question_instruction,
            input=input_data,
            tools=tools
        )

        # Extract tool call
        tool_call = None
        for item in response.output:
            if item.type == "function_call":
                tool_call = item
                break

        if not tool_call:
            return "Error: tool not called", None

        # Execute tool locally
        arguments = json.loads(tool_call.arguments)
        tool_result = get_summary_by_title(arguments["title"], book_dict)

        # Second call: generate final response using tool result
        second_response = client.responses.create(
            model="gpt-4.1-mini",
            instructions=final_instruction,
            input=[
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": f"User request: {user_input}"},
                        {"type": "input_text", "text": f"Book: {arguments['title']}"},
                        {"type": "input_text", "text": f"Summary: {tool_result}"}
                    ]
                }
            ]
        )

        final_text = second_response.output[0].content[0].text

        # Format output (separate explanation and summary)
        if "summary:" in final_text:
            parts = final_text.split("summary:")
            explanation = parts[0].strip()
            summary = parts[1].strip()
            return f"{explanation}\n\nSummary: {summary}", arguments["title"]
        else:
            return final_text, arguments["title"]

    # 2. Validate if input is a recommendation request
    if not is_valid_request(user_input):
        return "Please ask for a book recommendation (e.g., 'I want a fantasy book').", None

    # 3. Retrieve candidate books using RAG
    results = search_books(user_input)
    books = [item["title"] for item in results["metadatas"][0]]

    # Prepare input for LLM
    input_data = [
        {
            "role": "user",
            "content": [
                {"type": "input_text", "text": f"User request: {user_input}"},
                {"type": "input_text", "text": f"Candidate books: {books}"}
            ]
        }
    ]

    # First call: LLM selects book and calls tool
    response = client.responses.create(
        model="gpt-4.1-mini",
        instructions=recommendation_instruction,
        input=input_data,
        tools=tools
    )

    # Extract tool call
    tool_call = None
    for item in response.output:
        if item.type == "function_call":
            tool_call = item
            break

    if not tool_call:
        return "Error: tool not called", None

    # Execute tool
    arguments = json.loads(tool_call.arguments)
    tool_result = get_summary_by_title(arguments["title"], book_dict)

    # Second call: generate final recommendation
    second_response = client.responses.create(
        model="gpt-4.1-mini",
        instructions=final_instruction,
        input=[
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": f"User request: {user_input}"},
                    {"type": "input_text", "text": f"Book: {arguments['title']}"},
                    {"type": "input_text", "text": f"Summary: {tool_result}"}
                ]
            }
        ]
    )

    final_text = second_response.output[0].content[0].text

    # Format output
    if "summary:" in final_text:
        parts = final_text.split("summary:")
        recommendation = parts[0].strip()
        summary = parts[1].strip()
        return f"{recommendation}\n\nSummary: {summary}", arguments["title"]
    else:
        return final_text, arguments["title"]