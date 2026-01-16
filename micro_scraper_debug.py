import json
import requests

# Your USDA API key
API_KEY = "oiVB03Kiu9y8cbSwvNj6I4UD6Pbf0jNAOWHtXKzz"

# Load the original foods JSON
with open('foods.json', 'r') as f:
    data = json.load(f)

foods = data['foods']

# Base URLs for USDA FoodData Central API
SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"

# Test a few suspicious foods to see what's being matched
test_foods = [
    "Broccoli (raw)",
    "Spinach (raw)", 
    "Banana",
    "Orange",
    "Asparagus (raw)"
]

for food_name in test_foods:
    # Prepare search query
    search_query = food_name
    if "(raw)" in food_name.lower():
        search_query = search_query.replace("(raw)", "").strip() + " raw"
    
    # Search for the food
    search_body = {
        "query": search_query,
        "dataType": ["SR Legacy", "Foundation", "Branded"],
        "pageSize": 5,  # Get top 5 results to see what's being matched
        "sortBy": "dataType.keyword",
        "sortOrder": "asc"
    }
    search_response = requests.post(SEARCH_URL, params={"api_key": API_KEY}, json=search_body)
    
    if search_response.status_code != 200:
        print(f"Error searching for {food_name}: {search_response.text}")
        continue
    
    search_data = search_response.json()
    if not search_data.get("foods"):
        print(f"No results found for {food_name}")
        continue
    
    print(f"\n{'='*80}")
    print(f"Food: {food_name}")
    print(f"Search query: {search_query}")
    print(f"{'='*80}")
    
    for i, result in enumerate(search_data["foods"][:5]):
        print(f"\n{i+1}. {result['description']}")
        print(f"   FDC ID: {result['fdcId']}")
        print(f"   Data Type: {result.get('dataType', 'N/A')}")
        print(f"   Brand: {result.get('brandOwner', 'N/A')}")




