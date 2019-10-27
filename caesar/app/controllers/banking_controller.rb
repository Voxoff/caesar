# Kitchup style all in one controller
class BankingController < ApplicationController
  #
  access token => @
  def get_access_token
    exchange_token_response =
      client.item.public_token.exchange(params['public_token'])
    access_token = exchange_token_response['access_token']
    pretty_print_response(exchange_token_response)

    content_type :json
    exchange_token_response.to_json
  end

  # Retrieve Transactions for an Item
  # https://plaid.com/docs/#transactions
  def transactions
    now = Date.today
    thirty_days_ago = (now - 30)
    begin
      product_response =
        client.transactions.get(access_token, thirty_days_ago, now)
      pretty_print_response(product_response)
      content_type :json
      { transactions: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve ACH or ETF account numbers for an Item
  # https://plaid.com/docs/#auth
  def auth
    begin
      product_response = client.auth.get(access_token)
      pretty_print_response(product_response)
      content_type :json
      { auth: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve Identity data for an Item
  # https://plaid.com/docs/#identity
  def identity
    begin
      product_response = client.identity.get(access_token)
      pretty_print_response(product_response)
      content_type :json
      { identity: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve real-time balance data for each of an Item's accounts
  # https://plaid.com/docs/#balance
  def balance
    begin
      product_response = client.accounts.balance.get(access_token)
      pretty_print_response(product_response)
      content_type :json
      { balance: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve an Item's accounts
  # https://plaid.com/docs/#accounts
  def accounts
    begin
      product_response = client.accounts.get(access_token)
      pretty_print_response(product_response)
      content_type :json
      { accounts: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve Holdings data for an Item
  # https://plaid.com/docs/#investments
  def holdings
    begin
      product_response = client.investments.holdings.get(access_token)
      pretty_print_response(product_response)
      content_type :json
      { holdings: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end

  # Retrieve Investment Transactions for an Item
  # https://plaid.com/docs/#investments
  def investment_transactions
    now = Date.today
    thirty_days_ago = (now - 30)
    begin
      product_response = client.investments.transactions.get(access_token, thirty_days_ago, now)
      pretty_print_response(product_response)
      content_type :json
      { investment_transactions: product_response }.to_json
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end
  end


  # Create and then retrieve an Asset Report for one or more Items. Note that an
  # Asset Report can contain up to 100 items, but for simplicity we're only
  # including one Item here.
  # https://plaid.com/docs/#assets
  def assets
    begin
      asset_report_create_response =
        client.asset_report.create([access_token], 10, {})
      pretty_print_response(asset_report_create_response)
    rescue Plaid::PlaidAPIError => e
      error_response = format_error(e)
      pretty_print_response(error_response)
      content_type :json
      error_response.to_json
    end

    asset_report_token = asset_report_create_response['asset_report_token']

    asset_report_json = nil
    num_retries_remaining = 20
    while num_retries_remaining > 0
      begin
        asset_report_get_response = client.asset_report.get(asset_report_token)
        asset_report_json = asset_report_get_response['report']
        break
      rescue Plaid::PlaidAPIError => e
        if e.error_code == 'PRODUCT_NOT_READY'
          num_retries_remaining -= 1
          sleep 1
          next
        end
        error_response = format_error(e)
        pretty_print_response(error_response)
        content_type :json
        return error_response.to_json
      end
    end

    if asset_report_json.nil?
      content_type :json
      return {
        error: {
          error_code: 0,
          error_message: 'Timed out when polling for Asset Report'
        }
      }.to_json
    end

    asset_report_pdf = client.asset_report.get_pdf(asset_report_token)

    content_type :json
    {
      json: asset_report_json,
      pdf: Base64.encode64(asset_report_pdf)
    }.to_json
  end

  # Retrieve high-level information about an Item
  # https://plaid.com/docs/#retrieve-item
  def item
    item_response = client.item.get(access_token)
    institution_response =
      client.institutions.get_by_id(item_response['item']['institution_id'])
    content_type :json
    { item: item_response['item'],
      institution: institution_response['institution'] }.to_json
  end

  def set_access_token
    access_token = params['access_token']
    item = client.item.get(access_token)
    content_type :json
    { error: false, item_id: item['item']['item_id'] }.to_json
  end

  def format_error(err)
    { error: {
        error_code: err.error_code,
        error_message: err.error_message,
        error_type: err.error_type
      }
    }
  end

  def pretty_print_response(response)
    puts JSON.pretty_generate(response)
  end
end
