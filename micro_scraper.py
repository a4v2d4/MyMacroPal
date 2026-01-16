import json
import requests

# Placeholder for your USDA API key
API_KEY = "oiVB03Kiu9y8cbSwvNj6I4UD6Pbf0jNAOWHtXKzz"  # Replace with your actual API key from https://fdc.nal.usda.gov/api-key-signup.html

# Load the original foods JSON (assuming it's saved as 'foods.json' in the current directory)
with open('foods.json', 'r') as f:
    data = json.load(f)

foods = data['foods']

# Define the full list of 34 micronutrients
micronutrients_list = [
    "Vitamin A",
    "Vitamin C",
    "Vitamin D",
    "Vitamin E",
    "Vitamin K1 (Phylloquinone)",
    "Vitamin K2 (Menaquinone)",
    "Thiamin (B1)",
    "Riboflavin (B2)",
    "Niacin (B3)",
    "Pantothenic Acid (B5)",
    "Vitamin B6",
    "Biotin (B7)",
    "Folate (B9)",
    "Vitamin B12",
    "Choline",
    "Calcium",
    "Chromium",
    "Copper",
    "Iodine",
    "Iron",
    "Magnesium",
    "Manganese",
    "Molybdenum",
    "Phosphorus",
    "Potassium",
    "Selenium",
    "Sodium",
    "Zinc",
    "Omega-3",
    "Omega-6",
    "Saturated Fat",
    "Trans Fat",
    "Cholesterol",
    "Sugar"
]

# Mapping from user's micronutrient names to USDA nutrient names
# Units are as per USDA (e.g., mg, ug, g) and will be scaled per serving
nutrient_map = {
    "Vitamin A": "Vitamin A, RAE",  # ug
    "Vitamin C": "Vitamin C, total ascorbic acid",  # mg
    "Vitamin D": "Vitamin D (D2 + D3)",  # ug
    "Vitamin E": "Vitamin E (alpha-tocopherol)",  # mg
    "Vitamin K1 (Phylloquinone)": "Vitamin K (phylloquinone)",  # ug
    "Vitamin K2 (Menaquinone)": "Vitamin K (menaquinone-4)",  # ug (if available, else 0)
    "Thiamin (B1)": "Thiamin",  # mg
    "Riboflavin (B2)": "Riboflavin",  # mg
    "Niacin (B3)": "Niacin",  # mg
    "Pantothenic Acid (B5)": "Pantothenic acid",  # mg
    "Vitamin B6": "Vitamin B-6",  # mg
    "Biotin (B7)": "Biotin",  # ug
    "Folate (B9)": "Folate, total",  # ug
    "Vitamin B12": "Vitamin B-12",  # ug
    "Choline": "Choline, total",  # mg
    "Calcium": "Calcium, Ca",  # mg
    "Chromium": "Chromium, Cr",  # ug
    "Copper": "Copper, Cu",  # mg
    "Iodine": "Iodine, I",  # ug
    "Iron": "Iron, Fe",  # mg
    "Magnesium": "Magnesium, Mg",  # mg
    "Manganese": "Manganese, Mn",  # mg
    "Molybdenum": "Molybdenum, Mo",  # ug
    "Phosphorus": "Phosphorus, P",  # mg
    "Potassium": "Potassium, K",  # mg
    "Selenium": "Selenium, Se",  # ug
    "Sodium": "Sodium, Na",  # mg
    "Zinc": "Zinc, Zn",  # mg
    "Saturated Fat": "Fatty acids, total saturated",  # g
    "Trans Fat": "Fatty acids, total trans",  # g
    "Cholesterol": "Cholesterol",  # mg
    "Sugar": "Sugars, total including NLEA"  # g
}
# Note: Omega-3 and Omega-6 are special cases (sum of relevant fatty acids)
# Vitamin K2 may use "Vitamin K (menaquinone-4)" if present

# Base URLs for USDA FoodData Central API
SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"
FOOD_URL = "https://api.nal.usda.gov/fdc/v1/food/"

# Function to fetch USDA data for a food
def fetch_usda_nutrients(food_name):
    # Prepare search query (handle qualifiers like (raw), (cooked))
    search_query = food_name
    if "(raw)" in food_name.lower():
        search_query = search_query.replace("(raw)", "").strip() + " raw"
    elif "(cooked)" in food_name.lower():
        search_query = search_query.replace("(cooked)", "").strip() + " cooked"
    elif "(uncooked)" in food_name.lower():
        search_query = search_query.replace("(uncooked)", "").strip() + " uncooked"

    # Search for the food (prefer SR Legacy, Foundation, then Branded)
    search_body = {
        "query": search_query,
        "dataType": ["SR Legacy", "Foundation", "Branded"],
        "pageSize": 1,
        "sortBy": "dataType.keyword",
        "sortOrder": "asc"
    }
    search_response = requests.post(SEARCH_URL, params={"api_key": API_KEY}, json=search_body)
    
    if search_response.status_code != 200:
        print(f"Error searching for {food_name}: {search_response.text}")
        return None
    
    search_data = search_response.json()
    if not search_data.get("foods"):
        print(f"No results found for {food_name}")
        return None
    
    fdc_id = search_data["foods"][0]["fdcId"]
    
    # Fetch detailed food data
    food_response = requests.get(f"{FOOD_URL}{fdc_id}", params={"api_key": API_KEY})
    
    if food_response.status_code != 200:
        print(f"Error fetching details for {food_name} (fdcId: {fdc_id}): {food_response.text}")
        return None
    
    food_data = food_response.json()
    nutrients = {nut["nutrient"]["name"]: nut.get("amount", 0) for nut in food_data.get("foodNutrients", [])}
    
    return nutrients

# Process each food
for food in foods:
    food_name = food["name"]
    print(f"Processing {food_name}...")
    
    usda_nutrients = fetch_usda_nutrients(food_name)
    
    if usda_nutrients is None:
        # If no data, initialize all to 0
        food["micronutrients"] = {nut: 0.0 for nut in micronutrients_list}
        continue
    
    # Scale factor: USDA data is per 100g, scale to per serving
    scale = food["gramsPerServing"] / 100.0
    
    # Initialize micronutrients dict with 0s
    micronutrients = {nut: 0.0 for nut in micronutrients_list}
    
    # Fill in values from USDA
    for user_nut, usda_nut in nutrient_map.items():
        if usda_nut and usda_nut in usda_nutrients:
            micronutrients[user_nut] = round(usda_nutrients[usda_nut] * scale, 1)  # Round to 1 decimal, matching existing data
    
    # Special handling for Omega-3: sum all n-3 fatty acids (in g)
    omega3 = sum(v for k, v in usda_nutrients.items() if "fatty" in k.lower() and "n-3" in k.lower())
    micronutrients["Omega-3"] = round(omega3 * scale, 1)
    
    # Special handling for Omega-6: sum all n-6 fatty acids (in g)
    omega6 = sum(v for k, v in usda_nutrients.items() if "fatty" in k.lower() and "n-6" in k.lower())
    micronutrients["Omega-6"] = round(omega6 * scale, 1)
    
    # Special handling for Vitamin K2: if menaquinone present
    k2 = sum(v for k, v in usda_nutrients.items() if "menaquinone" in k.lower())
    if k2 > 0:
        micronutrients["Vitamin K2 (Menaquinone)"] = round(k2 * scale, 1)
    
    # Overwrite with existing if present (but prioritize USDA for updates)
    # Note: Existing partial data is overwritten with USDA values where available
    
    food["micronutrients"] = micronutrients

# Save the updated JSON
with open('updated_foods.json', 'w') as f:
    json.dump(data, f, indent=2)

print("Updated JSON saved to 'updated_foods.json'")