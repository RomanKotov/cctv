defmodule Cctv.Telegram do
  def send_message(text) do
    IO.inspect(text)
    bot_token = System.get_env("CCTV_TELEGRAM_BOT_TOKEN", "") |> String.trim()
    chat_id = System.get_env("CCTV_TELEGRAM_CHAT_ID", "") |> String.trim()

    telegram_is_configured = "" not in [bot_token, chat_id]

    if telegram_is_configured do
      Req.post!(
        "https://api.telegram.org/bot#{bot_token}/sendMessage",
        {:json, %{chat_id: chat_id, text: text, disable_notification: true}}
      )
    end
  end
end
