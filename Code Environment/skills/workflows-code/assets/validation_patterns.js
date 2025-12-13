/**
 * Defense-in-Depth Validation Patterns
 * Production-ready validation templates
 *
 * Validates at every layer to make errors structurally impossible
 */

/**
 * Contact Form with Multi-Layer Validation
 * Example implementation of defense-in-depth for form handling
 */
class ContactForm {
  constructor(formElement) {
    // Layer 1: Constructor validation
    if (!formElement) {
      throw new Error('[ContactForm] Form element required');
    }

    this.form = formElement;
    this.setupValidation();
  }

  setupValidation() {
    this.form.addEventListener('submit', (e) => {
      e.preventDefault();
      this.handleSubmit();
    });

    // Real-time validation
    const inputs = this.form.querySelectorAll('input, textarea');
    inputs.forEach(input => {
      input.addEventListener('blur', () => this.validateField(input));
    });
  }

  validateField(field) {
    // Layer 2: Field-level validation
    const value = field.value?.trim();
    const fieldName = field.name;

    // Clear previous errors
    this.clearFieldError(field);

    // Required field check
    if (field.hasAttribute('required') && !value) {
      this.showFieldError(field, `${fieldName} is required`);
      return false;
    }

    // Type-specific validation
    switch (field.type) {
      case 'email':
        if (value && !this.isValidEmail(value)) {
          this.showFieldError(field, 'Invalid email address');
          return false;
        }
        break;

      case 'tel':
        if (value && !this.isValidPhone(value)) {
          this.showFieldError(field, 'Invalid phone number');
          return false;
        }
        break;
    }

    return true;
  }

  isValidEmail(email) {
    // Layer 3: Format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  isValidPhone(phone) {
    const cleaned = phone.replace(/[\s\-\(\)]/g, '');
    return /^\d{10,15}$/.test(cleaned);
  }

  async handleSubmit() {
    console.log('[ContactForm] Submitting...');

    // Layer 2: Validate all fields
    const fields = this.form.querySelectorAll('input, textarea');
    let isValid = true;

    fields.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false;
      }
    });

    if (!isValid) {
      console.warn('[ContactForm] Validation failed');
      return;
    }

    // Layer 3: Collect and sanitize data
    const formData = new FormData(this.form);
    const data = {
      name: this.sanitizeText(formData.get('name')),
      email: this.sanitizeEmail(formData.get('email')),
      message: this.sanitizeText(formData.get('message'))
    };

    // Final validation
    if (!data.name || !data.email || !data.message) {
      console.error('[ContactForm] Sanitization removed all content');
      this.showFormError('Please check your input and try again');
      return;
    }

    // Submit
    try {
      const result = await this.submitToAPI(data);

      // Layer 4: Validate API response
      if (result && result.success) {
        this.showFormSuccess('Message sent successfully!');
        this.form.reset();
      } else {
        throw new Error(result?.message || 'Submission failed');
      }

    } catch (error) {
      console.error('[ContactForm] Submission failed:', error);
      this.showFormError('Failed to send message. Please try again.');
    }
  }

  sanitizeText(text) {
    if (!text || typeof text !== 'string') return '';

    return text
      .trim()
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .slice(0, 1000);
  }

  sanitizeEmail(email) {
    if (!email || typeof email !== 'string') return '';

    return email
      .toLowerCase()
      .trim()
      .slice(0, 254);
  }

  async submitToAPI(data) {
    const response = await fetch('/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    return response.json();
  }

  showFieldError(field, message) {
    field.classList.add('error');
    const errorEl = field.parentElement.querySelector('.error-message');
    if (errorEl) errorEl.textContent = message;
  }

  clearFieldError(field) {
    field.classList.remove('error');
    const errorEl = field.parentElement.querySelector('.error-message');
    if (errorEl) errorEl.textContent = '';
  }

  showFormSuccess(message) {
    const successEl = this.form.querySelector('[form-success]');
    if (successEl) {
      successEl.textContent = message;
      successEl.style.display = 'block';
    }
  }

  showFormError(message) {
    const errorEl = this.form.querySelector('[form-error]');
    if (errorEl) {
      errorEl.textContent = message;
      errorEl.style.display = 'block';
    }
  }
}

/**
 * Safe DOM Manipulation Class
 * Validates at every layer to prevent DOM errors
 */
class SafeDOM {
  static createElement(tag, attributes = {}, textContent = '') {
    // Layer 1: Input validation
    if (!tag || typeof tag !== 'string') {
      console.error('[SafeDOM] Invalid tag:', tag);
      return null;
    }

    try {
      const element = document.createElement(tag);

      // Layer 2: Attribute validation
      if (attributes && typeof attributes === 'object') {
        Object.entries(attributes).forEach(([key, value]) => {
          if (typeof value === 'string') {
            element.setAttribute(key, this.sanitizeAttribute(value));
          }
        });
      }

      // Layer 3: Content validation
      if (textContent) {
        element.textContent = this.sanitizeText(String(textContent));
      }

      return element;

    } catch (error) {
      console.error('[SafeDOM] Element creation failed:', error);
      return null;
    }
  }

  static querySelector(selector, context = document) {
    // Layer 1: Selector validation
    if (!selector || typeof selector !== 'string') {
      console.error('[SafeDOM] Invalid selector:', selector);
      return null;
    }

    try {
      const element = context.querySelector(selector);

      // Layer 2: Result validation
      if (!element) {
        console.warn(`[SafeDOM] Element not found: ${selector}`);
        return null;
      }

      return element;

    } catch (error) {
      console.error('[SafeDOM] Query failed:', error);
      return null;
    }
  }

  static sanitizeText(text) {
    if (typeof text !== 'string') return '';

    return text
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;');
  }

  static sanitizeAttribute(value) {
    if (typeof value !== 'string') return '';

    return value
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }
}

/**
 * API Client with Multi-Layer Error Handling
 */
class APIClient {
  constructor(baseURL) {
    // Layer 1: Constructor validation
    if (!baseURL || typeof baseURL !== 'string') {
      throw new Error('[API] Base URL required');
    }

    this.baseURL = baseURL.replace(/\/$/, '');
  }

  async get(endpoint, params = {}) {
    return this.request('GET', endpoint, null, params);
  }

  async post(endpoint, data) {
    return this.request('POST', endpoint, data);
  }

  async request(method, endpoint, data = null, params = {}) {
    // Layer 1: Method validation
    const allowedMethods = ['GET', 'POST', 'PUT', 'DELETE'];
    if (!allowedMethods.includes(method)) {
      throw new Error(`[API] Invalid HTTP method: ${method}`);
    }

    // Layer 2: Endpoint validation
    if (!endpoint || typeof endpoint !== 'string') {
      throw new Error('[API] Endpoint required');
    }

    const url = new URL(`${this.baseURL}${endpoint}`);

    // Add query parameters
    if (method === 'GET' && params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== null && value !== undefined) {
          url.searchParams.append(key, String(value));
        }
      });
    }

    const options = {
      method,
      headers: { 'Content-Type': 'application/json' }
    };

    if (data && ['POST', 'PUT'].includes(method)) {
      options.body = JSON.stringify(data);
    }

    try {
      const response = await fetch(url, options);

      // Layer 3: Response validation
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      // Layer 4: JSON validation
      const json = await response.json();

      if (json === null || json === undefined) {
        throw new Error('[API] Empty response');
      }

      return json;

    } catch (error) {
      console.error(`[API] Request failed:`, error);
      throw error;
    }
  }
}

// Export if using modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    ContactForm,
    SafeDOM,
    APIClient
  };
}
