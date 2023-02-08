/* 
    export.cpp
    Writes stats from slices or tensors into .csv files
    Clemson University and Argonne National Laboratory
*/

#include "compress.h"
#include <iomanip>

void exportcsv(pressio_options options, std::string output_file) {

    std::vector<std::string> hdrs =
    {"info:filename", "info:filepath", "info:dataset", "info:dim1", "info:dim2", "info:dim3", 
     "global:value_std", "global:compression_ratio", "global:value_range",
     "block:total_count", "block:number", "block:dim1", "block:dim2", "block:dim3", 
     "block:method","block:loc1", "block:loc2", "block:loc3",
     "stat:n100", "stat:n99", "stat:n999", "stat:n9999", "stat:qentropy",
     "info:bound_type", "info:compressor", "info:error_bound", "size:compression_ratio",
     "error_stat:average_error", "error_stat:error_range", "error_stat:mse",
     "error_stat:psnr", "error_stat:rmse", "error_stat:value_max", "error_stat:value_mean",
     "error_stat:value_min", "error_stat:value_range", "error_stat:value_std", "size:bit_rate",
    };
    std::ifstream myFile_chk;
    myFile_chk.open(output_file);
    if (!myFile_chk) {
        // file doesn't exist yet
        // write headers
        std::ofstream myFile(output_file);
        for (auto each : hdrs){
            myFile << each << ',';
        }
        myFile << "\n";
    } else {
        myFile_chk.close();
    }
    std::ofstream myFile(output_file, std::ios::app);

    for (auto each : hdrs){
        pressio_option const& value = options.get(each);

        if(value.has_value()) {
            switch(value.type()) {
              case pressio_option_bool_type:
                myFile << std::boolalpha << value.get_value<bool>();
                break;
              case pressio_option_int8_type:
                myFile << value.get_value<int8_t>();
                break;
              case pressio_option_int16_type:
                myFile << value.get_value<int16_t>();
                break;
              case pressio_option_int32_type:
                myFile << value.get_value<int32_t>();
                break;
              case pressio_option_int64_type:
                myFile << value.get_value<int64_t>();
                break;
              case pressio_option_uint8_type:
                myFile << value.get_value<uint8_t>();
                break;
              case pressio_option_uint16_type:
                myFile << value.get_value<uint16_t>();
                break;
              case pressio_option_uint32_type:
                myFile << value.get_value<uint32_t>();
                break;
              case pressio_option_uint64_type:
                myFile << value.get_value<uint64_t>();
                break;
              case pressio_option_double_type:
                myFile << value.get_value<double>();
                break;
              case pressio_option_float_type:
                myFile << value.get_value<float>();
                break;
              case pressio_option_charptr_type:
                myFile << std::quoted(value.get_value<std::string>());
                break;
              case pressio_option_charptr_array_type:
                {
                  auto const& entries = value.get_value<std::vector<std::string>>();
                  myFile << "\"[";
                  for (auto const& entry : entries) {
                    myFile << std::quoted(entry) << ',';
                  }
                  myFile << "]\"";
                  break;
                }
              case pressio_option_data_type:
                myFile << value.get_value<pressio_data>();
                break;
              case pressio_option_userptr_type:
                myFile << value.get_value<void*>();
                break;
              case pressio_option_unset_type:
              default:
                myFile << "None";
            }
          } else {
            // myFile << ',';
          }
          if(each != hdrs.back()) {
            myFile << ',';
          } else {
            myFile << '\n';
          }
    }
    myFile.close();
}