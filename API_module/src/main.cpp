#include <iostream>
#include <cpprest/http_client.h>
#include <cpprest/filestream.h>
#include <utility>

#define nL "\n" 
using namespace std;
using namespace web;
using namespace web::http;
using namespace web::http::client;

int main() {
  cout << "started" << nL;
  cout << "version:" << __cplusplus << nL;

  std::string api_key = "XoqNKfiUjJtIHjd1dkOPhQ_qFtrLGiZ4";
  std::string symbol = "AAPL";

  // web::uri_builder builder(U("/v2/last/nbbo/" + symbol));
  web::uri_builder builder(U("/v3/reference/dividends"));
  builder.append_query(U("apiKey"), api_key);

  web::http::client::http_client client(U("https://api.polygon.io"));

  client.request(
    web::http::methods::GET,
    builder.to_string())
      .then([](web::http::http_response response) {
          if (response.status_code() == web::http::status_codes::OK) {
            return response.extract_json();
          } else {
            std::cerr << "req failed lmao, status code: " << response.status_code() << nL;
            return pplx::task_from_result(web::json::value());
          }
      })

      .then([](web::json::value json_result) {
        std::cout << "response: " << json_result.serialize() << nL;
      })
    .wait();




  return 0;
}

