#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <algorithm>
#include <iostream>
#include <map>
#include <string>
#include <fstream>
#include <functional>
#include <vector>

using std::string;
using std::cout;
using std::endl;
using std::map;
using std::ifstream;
using std::getline;
using std::vector;
using std::stoi;
using std::pair;
using std::mem_fun_ref;
using std::ofstream;

#define P2_FILE "P2"
#define MY_PATH "C:\\lena.ascii.pgm"
#define OUTPUT_PATH "updated_lena.pgm"

void remove_empty_strings(vector<string>& strings);
size_t split(const string& text, vector<string>& parameters, char separator);

struct coordinates;
struct pixel;

class Photo
{
public:
	Photo(string file_path);

	void filter_negative();
	void save_file(string file_path);
	~Photo();

private:
	vector<pixel*>* image_pixels_;
	int height_;
	int width_;
	int max_gray_value_;
	string image_comment_;

	// Loading image
	void load_image(const string file_path);
	void load_image_size(ifstream* input);
	void load_max_gray(ifstream* input);
	void add_pixel(int row_counter, int column_counter, vector<std::basic_string<char>>* image_row, int i) const;
	void load_pixels(ifstream* input, int row_counter, int column_counter, string current_line) const;

	// Pixel filter methods
	int Photo::negative(int value);
};

int main()
{
	string my_path = MY_PATH;
	auto photo = new Photo(my_path);
	photo->filter_negative();

	photo->save_file(OUTPUT_PATH);
	delete photo;
	return 0;
}

void remove_empty_strings(vector<string>& strings)
{
	vector<string>::iterator it = remove_if(strings.begin(), strings.end(), mem_fun_ref(&string::empty));
	// erase the removed elements
	strings.erase(it, strings.end());
}

size_t split(const string& text, vector<string>& parameters, const char separator)
{
	size_t pos = text.find(separator);
	size_t initialPos = 0;
	parameters.clear();

	// Decompose statement
	while (pos != string::npos)
	{
		parameters.push_back(text.substr(initialPos, pos - initialPos));
		initialPos = pos + 1;

		pos = text.find(separator, initialPos);
	}

	// Add the last one
	parameters.push_back(text.substr(initialPos, std::min(pos, text.size()) - initialPos + 1));

	remove_empty_strings(parameters);

	return parameters.size();
}

struct coordinates
{
	int x;
	int y;
};

struct pixel
{
	int value;
	coordinates* coordinates;
};


Photo::Photo(string file_path)
{
	image_pixels_ = new vector<pixel*>();
	load_image(file_path);
}

void Photo::filter_negative()
{
	for (int i = 0; i < image_pixels_->size(); i++)
	{
		image_pixels_->at(i)->value = negative(image_pixels_->at(i)->value);
	}
}

void Photo::save_file(string file_path)
{
	ofstream processed_file(file_path);

	processed_file << P2_FILE << "\n";
	processed_file << image_comment_ << "\n";
	processed_file << width_ << "  " << height_ << "\n";
	processed_file << max_gray_value_ << "\n";

	int current_row = 0;
	
	for (int i = 0; i < image_pixels_->size(); i++)
	{
		auto current_pixel = image_pixels_->at(i);

		if (current_pixel->coordinates->y != current_row)
		{
			current_row++;
			processed_file << "\n";
		} else
		{
			processed_file << " ";
		}
		processed_file << current_pixel->value << " ";
	}

	processed_file << "\n";
	processed_file.close();
}

void Photo::load_image_size(ifstream* input)
{
	string size_line;
	getline(*input, size_line);
	auto image_size = new vector<string>();
	split(size_line, *image_size, ' ');
	width_ = stoi(image_size->at(0));
	height_ = stoi(image_size->at(1));
	delete image_size;
}

void Photo::load_max_gray(ifstream* input)
{
	string max_gray;
	getline(*input, max_gray);
	max_gray_value_ = stoi(max_gray);
}

void Photo::add_pixel(int row_counter, int column_counter, vector<std::basic_string<char>>* image_row, int i) const
{
	const auto current_pixel = new pixel();
	const auto coords = new coordinates();

	coords->x = column_counter;
	coords->y = row_counter;

	current_pixel->coordinates = coords;
	current_pixel->value = stoi(image_row->at(i));
	image_pixels_->push_back(current_pixel);
}

void Photo::load_pixels(ifstream* input, int row_counter, int column_counter, string current_line) const
{
	while (getline(*input, current_line))
	{
		auto image_row = new vector<string>();
		split(current_line, *image_row, ' ');

		for (int i = 0; i < image_row->size(); i++)
		{
			add_pixel(row_counter, column_counter, image_row, i);
			column_counter++;
		}

		column_counter = 0;
		row_counter++;
		image_row->clear();
		delete image_row;
	}
}

int Photo::negative(int value)
{
	return max_gray_value_ - value;
}

void Photo::load_image(const string file_path)
{
	ifstream input(file_path);

	if (input.is_open())
	{
		string file_type;
		getline(input, file_type);
		if (file_type == P2_FILE)
		{
			getline(input, image_comment_);

			load_image_size(&input);
			load_max_gray(&input);
			int row_counter = 0;
			int column_counter = 0;

			string current_line;

			load_pixels(&input, row_counter, column_counter, current_line);
		}
	}
}


Photo::~Photo()
{
	delete image_pixels_;
}
