defmodule Gmail.HTTP do

  @moduledoc """
  HTTP request handling.
  """

  use GenServer
  import Poison, only: [decode: 1, encode: 1]
  alias HTTPoison.Response
  alias Gmail.OAuth2

  #  Server API {{{ #

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:get, url}, _from, state) do
    result =
      get_token
      |> get_headers
      |> get_with_headers
      |> make_request(url)
      |> do_parse_response
    {:reply, result, state}
  end

  def handle_call({:delete, url}, _from, state) do
    result =
      get_token
      |> get_headers
      |> delete_with_headers
      |> make_request(url)
      |> do_parse_response
    {:reply, result, state}
  end

  def handle_call({:post, url, data}, _from, state) do
    result =
      get_token
      |> get_headers
      |> post_with_headers
      |> make_request_with_data(url, encode(data))
      |> do_parse_response
    {:reply, result, state}
  end

  def handle_call({:put, url, data}, _from, state) do
    result =
      get_token
      |> get_headers
      |> put_with_headers
      |> make_request_with_data(url, encode(data))
      |> do_parse_response
    {:reply, result, state}
  end

  def handle_call({:patch, url, data}, _from, state) do
    result =
      get_token
      |> get_headers
      |> patch_with_headers
      |> make_request_with_data(url, encode(data))
      |> do_parse_response
    {:reply, result, state}
  end

  #  }}} Server API #

  #  Client API {{{ #

  @doc """
  Performs an HTTP POST request.
  """
  @spec post(String.t, map) :: {atom, map}
  def post(url, data) do
    GenServer.call(__MODULE__, {:post, url, data})
  end

  @doc """
  Performs an HTTP PUT request.
  """
  @spec put(String.t, map) :: {atom, map}
  def put(url, data) do
    GenServer.call(__MODULE__, {:put, url, data})
  end

  @doc """
  Performs an HTTP PATCH request.
  """
  @spec patch(String.t, map) :: {atom, map}
  def patch(url, data) do
    GenServer.call(__MODULE__, {:patch, url, data})
  end

  @doc """
  Performs an HTTP GET request.
  """
  @spec get(String.t) :: {atom, map}
  def get(url) do
    GenServer.call(__MODULE__, {:get, url})
  end

  @doc """
  Performs an HTTP DELETE request.
  """
  @spec delete(String.t) :: {atom, map} | nil
  def delete(url) do
    GenServer.call(__MODULE__, {:delete, url})
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec do_parse_response({atom, Response.t}) :: {atom, map}
  defp do_parse_response({:ok, %Response{body: body}}) when byte_size(body) > 0 do
    decode(body)
  end

  defp do_parse_response({:ok, _response}) do
    nil
  end

  @spec get_headers(String.t) :: [{String.t, String.t}]
  defp get_headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  @spec get_with_headers(list(tuple)) :: (String.t -> Response.t)
  defp get_with_headers(headers) do
    fn(url) -> HTTPoison.get(url, headers) end
  end

  @spec delete_with_headers(list(tuple)) :: (String.t -> Response.t)
  defp delete_with_headers(headers) do
    fn(url) -> HTTPoison.delete(url, headers) end
  end

  @spec post_with_headers(list(tuple)) :: (String.t, String.t -> Response.t)
  defp post_with_headers(headers) do
    fn(url, json) ->
      HTTPoison.post(url, json, headers)
    end
  end

  @spec put_with_headers(list(tuple)) :: (String.t, String.t -> Response.t)
  defp put_with_headers(headers) do
    fn(url, json) -> HTTPoison.put(url, json, headers) end
  end

  @spec patch_with_headers(list(tuple)) :: (String.t, String.t -> Response.t)
  defp patch_with_headers(headers) do
    fn(url, json) -> HTTPoison.patch(url, json, headers) end
  end

  @spec make_request((String.t -> Response.t), String.t) :: Response.t
  defp make_request(fun, url) do
    fun.(url)
  end

  @spec make_request_with_data((String.t, String.t -> Response.t), String.t, {atom, String.t}) :: Response.t
  defp make_request_with_data(fun, url, {:ok, json}) do
    fun.(url, json)
  end

  @spec get_token :: String.t
  defp get_token do
    %{access_token: token} = OAuth2.get_config
    token
  end

  #  }}} Private functions #

end
