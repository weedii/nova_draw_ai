"""
Script to analyze the JSON file and report missing attributes in steps.

This script checks that all steps have:
- step_en (English instruction)
- step_de (German instruction)
- image (image URL)

Generates a detailed report of all missing attributes.
"""

import json
from pathlib import Path
from collections import defaultdict


def analyze_json():
    """Analyze the JSON file for missing attributes."""

    json_path = Path(__file__).parent / "to_fill_db_tutorials.json"
    print(f"Analyzing JSON file: {json_path}\n")

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Track missing attributes
    missing_report = defaultdict(list)
    total_steps = 0
    total_tutorials = 0

    # Iterate through all categories, subjects, and tutorials
    for category, subjects in data.items():
        for subject, tutorials in subjects.items():
            for tutorial_key, steps in tutorials.items():
                total_tutorials += 1

                for step_number, step_data in enumerate(steps, start=1):
                    total_steps += 1

                    # Check for missing attributes
                    missing_attrs = []

                    if "step_en" not in step_data:
                        missing_attrs.append("step_en")
                    if "step_de" not in step_data:
                        missing_attrs.append("step_de")
                    if "image" not in step_data:
                        missing_attrs.append("image")

                    # If any attributes are missing, record them
                    if missing_attrs:
                        location = f"{category} > {subject} > {tutorial_key} > Step {step_number}"
                        missing_report[location] = missing_attrs

    # Generate report
    print("=" * 80)
    print("JSON ANALYSIS REPORT")
    print("=" * 80)
    print(f"\nTotal Tutorials: {total_tutorials}")
    print(f"Total Steps: {total_steps}")
    print(f"\nMissing Attributes: {len(missing_report)}")

    if missing_report:
        print("\n" + "=" * 80)
        print("DETAILED MISSING ATTRIBUTES")
        print("=" * 80)

        for location, missing_attrs in sorted(missing_report.items()):
            print(f"\n❌ {location}")
            print(f"   Missing: {', '.join(missing_attrs)}")

        print("\n" + "=" * 80)
        print("SUMMARY BY MISSING ATTRIBUTE")
        print("=" * 80)

        # Count by attribute type
        attr_count = defaultdict(int)
        for missing_attrs in missing_report.values():
            for attr in missing_attrs:
                attr_count[attr] += 1

        for attr, count in sorted(attr_count.items()):
            print(f"  {attr}: {count} missing")

        print("\n" + "=" * 80)
        print("LOCATIONS WITH MISSING ATTRIBUTES (sorted)")
        print("=" * 80)

        for i, location in enumerate(sorted(missing_report.keys()), 1):
            missing_attrs = missing_report[location]
            print(f"{i}. {location}")
            print(f"   Missing: {', '.join(missing_attrs)}")
    else:
        print("\n✅ All steps have all required attributes!")

    print("\n" + "=" * 80)
    print("END OF REPORT")
    print("=" * 80 + "\n")


if __name__ == "__main__":
    analyze_json()
