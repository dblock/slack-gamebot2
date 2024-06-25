## Use a Service

Before deploying, consider using and sponsoring [a free game bot service](https://gamebot.playplay.io) and not worrying about installation or maintenance.

### PlayPlay.io

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack@2x.png)](https://gamebot.playplay.io)

## Deploy Your Own

### Environment

See [.env.sample](.env.sample) for environment variables. 

#### Slack Keys

Create a Slack app and get `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_SIGNING_SECRET`, and `SLACK_VERIFICATION_TOKEN` from it.

#### GIPHY_API_KEY

Gamebot replies with animated GIFs. Obtain and set `GIPHY_API_KEY` from [developers.giphy.com](https://developers.giphy.com).

#### URL

This defaults to `http://localhost:5000` in development and `https://gamebot.playplay.io` in production.

#### API_URL

The root of your API location, used when displaying the API URL for teams when invoking `set api`.

#### STRIPE_API_KEY and STRIPE_API_PUBLISHABLE_KEY

The service on [playplay.io](https://gamebot.playplay.io) requires users to subscribe. The money is collected with Stripe, and requires two keys, a private key for creating subscriptions on the back-end, and a public key for tokenizing credit cards client-side.
