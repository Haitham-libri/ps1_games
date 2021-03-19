#pragma once
#include <glm/vec4.hpp>
#include <glm/vec3.hpp>
#include <glm/vec2.hpp>
enum class RenderType : int
{
	NONE,
	TEXTURED_ALBEDO,
	TEXTURED_LIT_FOG,
	TEXTURED_LIT_TRANSPARENT_FOG
};

struct Vertex
{
	Vertex(glm::vec3 pos, glm::vec2 uv, glm::vec3 normal, glm::vec4 color) : pos(pos), uv(uv), normal(normal), color(color) {};
	glm::vec3 pos;
	glm::vec2 uv;
	glm::vec3 normal;
	glm::vec4 color;

	static constexpr unsigned int sizeInBytes = 12 * sizeof(float);
};

namespace aie
{
	class Input;
};

/*Singleton class for miscelanious rendering requests for different render types with different shaders*/
class Renderer
{
public:
	static void init() { close(); singletonInstance = new Renderer(); }
	static Renderer* getInstance() { return singletonInstance; }
	static void close() { if (singletonInstance)delete singletonInstance; }

	void drawTexturedBrush(class TexturedBrush* tb);
	void doDebugInputs(aie::Input* input);
	Renderer();
	~Renderer();
private:

	bool debugWireFrameMode = false;

	unsigned int texBrushVaoID = 0;
	unsigned int texBrushIboID = 0;
	unsigned int texBrushVboID = 0;

	class Shader* shader_NONE = nullptr;
	class Shader* shader_TEXTURED_ALBEDO = nullptr;
	class Shader* shader_TEXTURED_LIT_FOG = nullptr;
	class Shader* shader_TEXTURED_LIT_TRANSPARENT_FOG = nullptr;

	static Renderer* singletonInstance;
};