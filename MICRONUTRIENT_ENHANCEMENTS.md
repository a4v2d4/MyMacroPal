# Micronutrient Tracking Enhancements

## Version 1.1.0 - Body Recomposition Focus

### What Changed

Enhanced micronutrient tracking to include often-overlooked nutrients critical for body recomposition, muscle building, and optimal metabolic function.

### New Micronutrients Added

#### 1. **Chromium** (35 mcg Daily Value)
- **Function**: Enhances insulin sensitivity and glucose metabolism
- **Body Recomposition Benefits**:
  - Improves nutrient partitioning (more nutrients to muscle, less to fat)
  - Supports lean mass gains by optimizing insulin function
  - Helps maintain stable blood sugar during cutting phases
- **USDA Mapping**: "Chromium"
- **Unit**: mcg (micrograms)

#### 2. **Iodine** (150 mcg Daily Value)
- **Function**: Essential for thyroid hormone production (T3/T4)
- **Body Recomposition Benefits**:
  - Regulates metabolic rate and energy expenditure
  - Critical for maintaining metabolism during caloric restriction
  - Supports optimal thyroid function for fat loss
- **USDA Mapping**: "Iodine"
- **Unit**: mcg (micrograms)

#### 3. **Molybdenum** (45 mcg Daily Value)
- **Function**: Required for enzyme cofactors in amino acid metabolism
- **Body Recomposition Benefits**:
  - Supports protein synthesis and amino acid utilization
  - Involved in breaking down sulfur-containing amino acids
  - Essential for detoxification processes during intense training
- **USDA Mapping**: "Molybdenum"
- **Unit**: mcg (micrograms)

#### 4. **Vitamin K Split** (K1: 120 mcg, K2: 90 mcg)
- **Previous**: Single "Vitamin K" entry
- **Now**: Separate tracking for K1 (Phylloquinone) and K2 (Menaquinone)
- **Why the Split**:
  - **Vitamin K1**: Blood clotting, found in leafy greens
  - **Vitamin K2**: Bone health, calcium metabolism, cardiovascular health, found in fermented foods and animal products
  - K1 and K2 have distinct metabolic roles and food sources
- **Body Recomposition Benefits of K2**:
  - Works synergistically with Vitamin D for calcium metabolism
  - Supports bone density during heavy training
  - May support cardiovascular health and arterial health
  - Important for athletes using high-dose Vitamin D supplementation
- **USDA Mapping**: 
  - K1: "Phylloquinone", "Vitamin K1", "Vitamin K (phylloquinone)"
  - K2: "Menaquinone", "Vitamin K2", "MK-4", "MK-7"
- **Unit**: mcg (micrograms)

### Already Included (But Often Overlooked)

These were already in the system but are worth highlighting:

- **Biotin (B7)** - 30 mcg: Protein synthesis, fat metabolism
- **Choline** - 550 mg: Liver function, fat metabolism, prevents fatty liver

### Total Micronutrients Tracked

**34 micronutrients** across three categories:
- **15 Vitamins** (including K1 and K2 separately)
- **13 Minerals** (including chromium, iodine, molybdenum)
- **6 Other nutrients** (fatty acids and limit nutrients)

### Technical Implementation

#### Code Changes

1. **Micronutrients.swift**:
   - Added `chromium`, `iodine`, `molybdenum` to mineral cases
   - Split `vitaminK` into `vitaminK1` and `vitaminK2`
   - Added Daily Value standards for new nutrients
   - Updated unit mappings (all new minerals use mcg)
   - Enhanced USDA nutrient mapper to recognize new nutrients
   - Added K1/K2 distinction in mapping logic

2. **FoodDetailView.swift**:
   - Updated micronutrient summary highlights to show K2, chromium, and iodine
   - Changed from 6 to 8 highlighted nutrients

3. **Documentation**:
   - Updated MICRONUTRIENTS_IMPLEMENTATION.md with new nutrients
   - Added body recomposition focus section
   - Updated version to 1.1.0

### Why These Matter for Body Recomposition

#### Chromium
Many athletes are deficient in chromium, especially during intense training or caloric restriction. Chromium deficiency can impair:
- Insulin sensitivity (worse nutrient partitioning)
- Glucose disposal (harder to build muscle)
- Fat loss progress (reduced metabolic efficiency)

#### Iodine
Iodine deficiency is common and can lead to:
- Reduced thyroid output (slower metabolism)
- Impaired fat loss despite caloric deficit
- Reduced training capacity and recovery
- Common in low-salt diets (iodized salt is a primary source)

#### Molybdenum
While deficiency is rare, athletes consuming high-protein diets benefit from optimal levels:
- Better amino acid metabolism
- Improved detoxification of training byproducts
- Enhanced recovery from intense training

#### Vitamin K2
Often overlooked compared to K1:
- Critical when supplementing with Vitamin D (which most athletes do)
- Prevents calcium from depositing in arteries
- Directs calcium to bones and teeth
- Important for bone density during weight-bearing exercise
- Different food sources than K1 (fermented foods, dairy, meat vs. leafy greens)

### Food Sources

To maximize these nutrients:

**Chromium-rich foods**:
- Broccoli, green beans
- Beef, poultry
- Whole grains, bran
- Black pepper, brewer's yeast

**Iodine-rich foods**:
- Seaweed (kelp, nori)
- Fish and seafood
- Dairy products
- Iodized salt
- Eggs

**Molybdenum-rich foods**:
- Legumes (beans, lentils, peas)
- Whole grains
- Nuts and seeds
- Leafy vegetables

**Vitamin K2-rich foods**:
- Natto (fermented soybeans) - highest source
- Hard cheeses (Gouda, Brie)
- Egg yolks
- Chicken, beef
- Fermented foods

**Vitamin K1-rich foods**:
- Leafy greens (kale, spinach, collards)
- Broccoli, Brussels sprouts
- Green beans, asparagus

### How to Use

1. **Search USDA foods** containing these nutrients
2. **View micronutrient details** in food detail screen
3. **Track daily progress** in the Vitamins & Minerals section
4. **Check DV%** to ensure optimal intake

The app will automatically:
- Extract these nutrients from USDA food data
- Calculate values based on serving size
- Sum daily totals across all meals
- Display progress bars and DV%

### Backward Compatibility

- Existing food entries will work normally
- Foods without these nutrients will show 0% (expected for most foods)
- No data migration needed
- All existing micronutrient features remain unchanged

### Performance Impact

- Minimal: Added 4 items to enum (K split into 2, plus 3 new minerals)
- Same efficient dictionary-based storage
- No impact on app performance

---

**Version**: 1.1.0  
**Date**: January 2026  
**Enhancement Type**: Feature addition  
**Breaking Changes**: None

