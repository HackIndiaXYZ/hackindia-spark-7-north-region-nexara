import csv
import json

def parse_eligibility_as_list(text):
    """Split eligibility text by ';' into clean sentences."""
    if not text:
        return []
    return [p.strip() for p in text.split(';') if p.strip()]

def main():
    # 1. Load schemes
    with open('schemes.csv', encoding='utf-8') as f:
        schemes_reader = csv.DictReader(f)
        schemes = {row['slug']: row for row in schemes_reader}

    # 2. Merge FAQs
    with open('schemes_faqs.csv', encoding='utf-8') as f:
        faq_reader = csv.DictReader(f)
        for row in faq_reader:
            slug = row['scheme_slug']
            if slug in schemes:
                schemes[slug].setdefault('faqs', []).append({
                    'question': row['question'],
                    'answer': row['answer']
                })

    # 3. Build final list with ordered fields (optional: alphabetize keys per object)
    scheme_list = []
    for slug, s in schemes.items():
        scheme_obj = {
            'id': slug,
            'name': s.get('scheme_name', ''),
            'short_title': s.get('short_title', ''),
            'level': s.get('level', ''),
            'state': s.get('state', ''),
            'ministry': s.get('ministry', ''),
            'department': s.get('department', ''),
            'beneficiary_type': s.get('beneficiary_type', ''),
            'benefit_type': s.get('benefit_type', ''),
            'categories': s.get('categories', '').split(';') if s.get('categories') else [],
            'sub_categories': s.get('sub_categories', ''),
            'tags': s.get('tags', '').split(';') if s.get('tags') else [],
            'brief_description': s.get('brief_description', ''),
            'detailed_description': s.get('detailed_description', ''),
            'benefits': s.get('benefits', ''),
            'eligibility_text': s.get('eligibility', ''),
            'eligibility_sentences': parse_eligibility_as_list(s.get('eligibility', '')),
            'exclusions': s.get('exclusions', ''),
            'application_mode': s.get('application_mode', ''),
            'application_process': s.get('application_process', ''),
            'documents_required': s.get('documents_required', ''),
            'references': s.get('references', ''),
            'apply_url': s.get('source_url', ''),
            'faqs': s.get('faqs', [])
        }
        # Sort the keys of each scheme for readability
        sorted_obj = {k: scheme_obj[k] for k in sorted(scheme_obj)}
        scheme_list.append(sorted_obj)

    # 4. Write beautifully formatted JSON
    with open('schemes_data.json', 'w', encoding='utf-8') as out:
        json.dump(
            scheme_list,
            out,
            indent=2,               # 2-space indentation
            sort_keys=False,        # we already sorted the dicts
            ensure_ascii=False,     # preserve Hindi characters
            separators=(',', ': ')  # clean separator spacing
        )

    print(f'Successfully written {len(scheme_list)} schemes to schemes_data.json')

if __name__ == '__main__':
    main()