import re
import datetime

# SQL Injection Patterns
SQL_PATTERNS = [
    r"(\%27)|(\')",             # Single quote
    r"(\-\-)",                  # Comment
    r"(\%23)|(#)",              # Comment
    r"((\%3D)|(=))[^\n]*((\%27)|(\')|(\-\-)|(\%3B)|(;))", # Meta-characters with =
    r"\w*((\%27)|(\'))((\%6F)|o|(\%4F))((\%72)|r|(\%52))", # ' or ...
    r"union\s+select",          # UNION SELECT
    r"exec(\s|\+)+(s|x)p\w+"    # EXEC ...
]

# XSS Patterns
XSS_PATTERNS = [
    r"<script>",
    r"javascript:",
    r"onerror=",
    r"onload=",
    r"<iframe>",
    r"src\s*=",
    r"alert\(",
]

def detect_sqli(data):
    """Checks string for SQL Injection patterns."""
    if not data:
        return None
    for pattern in SQL_PATTERNS:
        if re.search(pattern, data, re.IGNORECASE):
            return f"SQL Injection Detected (pattern: {pattern})"
    return None

def detect_xss(data):
    """Checks string for XSS patterns."""
    if not data:
        return None
    for pattern in XSS_PATTERNS:
        if re.search(pattern, data, re.IGNORECASE):
            return f"XSS Detected (pattern: {pattern})"
    return None

def analyze_request(request):
    """
    Analyzes Flask request headers, args, and form data for vectors.
    Returns (is_malicious, attack_type, payload)
    """
    vectors = []
    
    # Check URL arguments
    for key, value in request.args.items():
        vectors.append(value)
        
    # Check Form data
    for key, value in request.form.items():
        vectors.append(value)
        
    # Check JSON data (if applicable)
    if request.is_json:
        for key, value in request.json.items():
            vectors.append(str(value))

    for vector in vectors:
        sqli = detect_sqli(vector)
        if sqli:
            return True, "SQL Injection", vector
        
        xss = detect_xss(vector)
        if xss:
            return True, "XSS", vector
            
    return False, None, None
