# Spam Protection for Forms

Panda CMS provides multiple layers of accessible spam protection for contact forms and other user submissions. All methods are WCAG-compliant and don't require visual CAPTCHAs.

## Built-in Protection (No Configuration Required)

### 1. Timing-Based Detection

Forms automatically track when they were loaded and reject submissions that are:

- **Too fast** (< 3 seconds): Likely automated bots
- **Too stale** (> 24 hours): Expired form sessions

**Implementation**: Add the timestamp helper to your forms:

```erb
<%= form_with url: "/forms/#{@form.id}", method: :post do |f| %>
  <%= panda_cms_form_timestamp %>

  <%= f.text_field :name %>
  <%= f.email_field :email %>
  <%= f.text_area :message %>

  <%= f.submit "Send" %>
<% end %>
```

Or use the complete protected form helper:

```erb
<%= panda_cms_protected_form(@form) do |f| %>
  <%= f.text_field :name %>
  <%= f.email_field :email %>
  <%= f.text_area :message %>
  <%= f.submit "Send" %>
<% end %>
```

### 2. Invisible Honeypot (invisible_captcha gem)

A hidden field that bots typically fill but humans ignore. Already configured and active.

**How it works**:

- Adds an invisible field named "spinner" to forms
- Field is positioned off-screen with CSS
- If the field contains any value, submission is rejected
- Completely transparent to users and accessible

### 3. Rate Limiting

Limits submissions to **3 per IP address per 5 minutes**.

**Protection against**:

- Automated spam floods
- Distributed bot attacks
- Rapid-fire submissions

### 4. Content Analysis

Automatically detects spam patterns:

- **URL counting**: Rejects messages containing more than 3 URLs
- **Pattern detection**: Identifies common spam signatures

### 5. IP Address and User Agent Tracking

Every submission records:

- IP address (indexed for quick lookups)
- User agent string
- Submission timestamp

This data helps:

- Identify spam patterns
- Block repeat offenders
- Analyze attack sources

## Optional Advanced Protection

### Akismet Integration (Recommended for High-Traffic Sites)

Akismet is a cloud-based spam detection service used by WordPress and millions of sites. It's highly effective and accessible.

#### Setup

1. **Get an API key** from [Akismet.com](https://akismet.com/):
   - Free for personal/non-commercial sites
   - Paid plans for commercial sites

2. **Add the gem** to your Gemfile:

```ruby
gem 'rakismet'
```

3. **Configure** in `config/initializers/rakismet.rb`:

```ruby
Rakismet.setup do |config|
  config.key = Rails.application.credentials.dig(:akismet, :api_key)
  config.url = "https://yourdomain.com"
  config.app_name = "Your App Name"
  config.app_version = "1.0"
end
```

4. **Update the controller** to check with Akismet:

```ruby
# app/controllers/panda/cms/form_submissions_controller.rb

def create
  form = Panda::CMS::Form.find(params[:id])

  # Check with Akismet
  if akismet_spam?(params)
    log_spam_attempt(form, "akismet")
    redirect_to_fallback(form, spam: true)
    return
  end

  # ... rest of create action
end

private

def akismet_spam?(params)
  return false unless Rakismet.key.present?

  akismet = Rakismet::Client.new
  akismet.check(
    type: 'contact-form',
    author: params[:name],
    author_email: params[:email],
    content: params[:message],
    permalink: request.url,
    user_ip: request.remote_ip,
    user_agent: request.user_agent,
    referrer: request.referer
  )
rescue StandardError => e
  Rails.logger.error "Akismet check failed: #{e.message}"
  false # Don't reject on API errors
end
```

#### Advantages

- ✅ 99.99% spam detection accuracy
- ✅ Learns from millions of sites
- ✅ No user interaction required
- ✅ Fully accessible (no visual challenges)
- ✅ API-based (no frontend JavaScript)

#### Considerations

- Requires API key and internet connection
- Free tier has usage limits
- Shares data with Akismet servers (privacy consideration)

### ALTCHA Integration (Privacy-First Alternative)

ALTCHA is an open-source, self-hosted CAPTCHA alternative that uses proof-of-work challenges. It's WCAG 2.2 Level AA and EAA compliant.

#### Features

- ✅ Self-hosted (complete privacy control)
- ✅ No cookies, no tracking, no fingerprinting
- ✅ WCAG 2.2 AA and EAA compliant
- ✅ Open source (MIT license)
- ✅ 90% smaller than reCAPTCHA
- ✅ Works entirely in the browser

#### Setup

1. **Install ALTCHA** via npm or yarn:

```bash
npm install altcha
```

2. **Add to your forms** (JavaScript):

```html
<script type="module">
  import 'altcha';
</script>

<form>
  <altcha-widget
    challengeurl="/altcha/challenge"
    hidefooter
  ></altcha-widget>

  <!-- Your form fields -->
</form>
```

3. **Add challenge endpoint** to your Rails app:

```ruby
# config/routes.rb
get '/altcha/challenge', to: 'altcha#challenge'

# app/controllers/altcha_controller.rb
class AltchaController < ApplicationController
  def challenge
    # Generate ALTCHA challenge
    # See ALTCHA documentation for implementation
  end
end
```

4. **Validate in form controller**:

```ruby
def create
  if params[:altcha].blank? || !valid_altcha_solution?(params[:altcha])
    redirect_to_fallback(form, spam: true)
    return
  end

  # ... rest of create action
end
```

#### Advantages

- ✅ Complete privacy control (self-hosted)
- ✅ No external dependencies
- ✅ Fully accessible
- ✅ Open source
- ✅ Smaller bundle size than alternatives

#### Considerations

- Requires JavaScript on client side
- More complex setup than Akismet
- Need to implement challenge generation server-side

### Cloudflare Turnstile (Free Alternative)

Turnstile is Cloudflare's free, privacy-focused CAPTCHA replacement.

#### Features

- ✅ Free up to 1M requests/month
- ✅ WCAG 2.1 Level AA compliant
- ✅ No visual puzzles (behavioral analysis)
- ✅ Simple integration

#### Setup

1. **Get site and secret keys** from [Cloudflare Dashboard](https://dash.cloudflare.com/?to=/:account/turnstile)

2. **Add to your forms**:

```html
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>

<form>
  <div class="cf-turnstile" data-sitekey="your-site-key"></div>

  <!-- Your form fields -->
</form>
```

3. **Validate server-side**:

```ruby
def create
  if !valid_turnstile_response?(params[:'cf-turnstile-response'])
    redirect_to_fallback(form, spam: true)
    return
  end

  # ... rest of create action
end

private

def valid_turnstile_response?(token)
  return false if token.blank?

  response = Faraday.post('https://challenges.cloudflare.com/turnstile/v0/siteverify') do |req|
    req.body = {
      secret: Rails.application.credentials.dig(:turnstile, :secret_key),
      response: token,
      remoteip: request.remote_ip
    }.to_json
    req.headers['Content-Type'] = 'application/json'
  end

  result = JSON.parse(response.body)
  result['success']
rescue StandardError => e
  Rails.logger.error "Turnstile validation failed: #{e.message}"
  false
end
```

#### Advantages

- ✅ Free for most sites
- ✅ Backed by Cloudflare infrastructure
- ✅ Accessible
- ✅ Simple integration

#### Considerations

- Requires Cloudflare account
- JavaScript required on frontend
- Shares data with Cloudflare

## Monitoring and Analysis

### View Spam Logs

All spam attempts are logged with details:

```bash
# In your Rails logs
tail -f log/production.log | grep "Spam detected"
```

Example output:

```
Spam detected (timing) for form 123 from IP: 192.168.1.100
Spam detected (content) for form 123 from IP: 203.0.113.50
Rate limit exceeded for IP: 198.51.100.75
```

### Query Submission Data

Use the tracked IP addresses to analyze patterns:

```ruby
# Find submissions from specific IP
Panda::CMS::FormSubmission.where(ip_address: "192.168.1.100")

# Find submissions from last hour grouped by IP
Panda::CMS::FormSubmission
  .where("created_at > ?", 1.hour.ago)
  .group(:ip_address)
  .count

# Most active IPs (potential spam sources)
Panda::CMS::FormSubmission
  .group(:ip_address)
  .count
  .sort_by { |_, count| -count }
  .first(10)
```

### Block Repeat Offenders

Add IP blocking to your controller:

```ruby
BLOCKED_IPS = %w[
  192.168.1.100
  203.0.113.50
].freeze

before_action :block_banned_ips

def block_banned_ips
  if BLOCKED_IPS.include?(request.remote_ip)
    render plain: "Forbidden", status: :forbidden
  end
end
```

Or use [Rack::Attack](https://github.com/rack/rack-attack) for more sophisticated blocking.

## Recommended Setup by Site Type

### Personal/Small Sites

Use built-in protection (no additional setup):

- ✅ Timing detection
- ✅ Invisible honeypot
- ✅ Rate limiting
- ✅ Content analysis

### Medium-Traffic Sites

Add **Akismet** for additional protection:

- Built-in protection (above)
- + Akismet (free for personal use)

### High-Privacy Sites

Use **ALTCHA** for self-hosted solution:

- Built-in protection
- + ALTCHA (fully self-hosted)

### Sites Using Cloudflare

Use **Turnstile** for free Cloudflare integration:

- Built-in protection
- + Turnstile (if already using Cloudflare)

## Accessibility Compliance

All recommended solutions comply with:

- ✅ **WCAG 2.1 Level AA** (Web Content Accessibility Guidelines)
- ✅ **ADA** (Americans with Disabilities Act)
- ✅ **EAA** (European Accessibility Act 2025)
- ✅ **Section 508** (US Federal accessibility requirements)

Unlike traditional CAPTCHAs (image puzzles, audio challenges), these solutions:

- Don't require visual interpretation
- Don't require audio processing
- Don't require complex interactions
- Work with screen readers and assistive technology
- Don't frustrate legitimate users

## Avoiding reCAPTCHA

Google's reCAPTCHA has significant accessibility issues:

- ❌ Image puzzles are difficult for visually impaired users
- ❌ Audio challenges have poor quality and accents
- ❌ Requires multiple attempts even for legitimate users
- ❌ Tracks users across sites (privacy concern)
- ❌ Often flags legitimate users as suspicious

**We explicitly avoid reCAPTCHA** in favor of the accessible alternatives documented above.

## Further Reading

- [ALTCHA Documentation](https://altcha.org/)
- [Akismet API Documentation](https://akismet.com/developers/)
- [Cloudflare Turnstile Docs](https://developers.cloudflare.com/turnstile/)
- [invisible_captcha gem](https://github.com/markets/invisible_captcha)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
