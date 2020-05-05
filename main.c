/*
** BLABLA
** PERSONAL
** AUDIO VISUALIZER
*/

#include "include/function.h"

char *read_shader(char * filepath)
{
    struct stat st;
    int size = 0;
    int file;

    stat(filepath, &st);
    size = st.st_size;
    char *buffer = malloc(sizeof(char) * size + 1);

    buffer[size] = '\0';
    file = open(filepath, O_RDONLY);
    read(file, buffer, size);
    close(file);
    return (buffer);
}

int shader_program(unsigned int vertex, unsigned int fragment)
{
    int shaderProgram;
    int success;
    char infoLog[512];

    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertex);
    glAttachShader(shaderProgram, fragment);
    glLinkProgram(shaderProgram);
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if(!success) {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        printf("Shader program error : %s", infoLog);
    }
    return (shaderProgram);
}

int init_vertex_shader()
{
    unsigned int vertexShader;
    int success;
    char infoLog[512];
    const GLchar *const src = read_shader("shaders/vertexShader.glsl");

    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &src, NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        printf("Vertex shader compilation error : %s", infoLog);
    }
    return (vertexShader);
}

int init_fragment_shader()
{
    unsigned int fragmentShader;
    int success;
    char infoLog[512];
    const GLchar *const src = read_shader("shaders/fragmentShader.glsl");

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &src, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        printf("Fragment shader compilation error : %s", infoLog);
    }
    return (fragmentShader);
}



void poll_event(sfRenderWindow *window, sfEvent event)
{
    while (sfRenderWindow_pollEvent(window, &event))
    {
        if (event.type == sfEvtClosed) {
            sfRenderWindow_close(window);
        }
    }
}

void update(sfRenderWindow *window, sfEvent event)
{
    sfSound *song;
    sfSoundBuffer *soundBuffer;
    song = sfSound_create();
    soundBuffer = sfSoundBuffer_createFromFile("song.wav");
    sfSound_setBuffer(song, soundBuffer);
    sfSound_play(song);
    int sc = sfSoundBuffer_getSampleCount(soundBuffer);
    short *samples = malloc(sizeof(samples) * (sc));


    for (int i = 0; i < sc; i++)
        samples[i] = sfSoundBuffer_getSamples(soundBuffer)[i];
    int j = 0;



    float vertices[] = {
         1,  1, 0.0f,  // top right
         1, -1, 0.0f,  // bottom right
        -1, -1, 0.0f,  // bottom left
        -1,  1, 0.0f   // top left
    };
    unsigned int indices[] = {  // note that we start from 0!
        0, 1, 3,   // first triangle
        1, 2, 3    // second triangle
    };

    unsigned int VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    unsigned int EBO;
    glGenBuffers(1, &EBO);

    unsigned int vertexShader = init_vertex_shader();
    unsigned int fragmentShader = init_fragment_shader();
    unsigned int shaderProgram = shader_program(vertexShader, fragmentShader);
    glDetachShader(shaderProgram, vertexShader);
    glDetachShader(shaderProgram, fragmentShader);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);


    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glUseProgram(shaderProgram);

    float time = 0;
    float height = 2.0;
    float phase = 0.0;
    float glowness = 1.0;
    float mid;

    while (sfRenderWindow_isOpen(window)) {
       poll_event(window, event);
       sfRenderWindow_display(window);
       glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
       glClear(GL_COLOR_BUFFER_BIT);
       j = sfTime_asMilliseconds(sfSound_getPlayingOffset(song)) * 88.15;
       if(j > 500) {
           mid = 0;
           for(int i = -500; i < 500; i++) {
               mid += abs(samples[j - i]);
            }
            mid /= 1000;
        }
       time += 10;
       glowness = mid / 100000;
       phase = mid / 500;
       height = mid / 5000;
       glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
       GLint time_loc = glGetProgramResourceLocation(shaderProgram, GL_UNIFORM, "time");
       glProgramUniform1f(shaderProgram, time_loc, time);

       GLint height_loc = glGetProgramResourceLocation(shaderProgram, GL_UNIFORM, "height");
       glProgramUniform1f(shaderProgram, height_loc, height);

       GLint phase_loc = glGetProgramResourceLocation(shaderProgram, GL_UNIFORM, "phase");
       glProgramUniform1f(shaderProgram, phase_loc, phase);

       GLint glowness_loc = glGetProgramResourceLocation(shaderProgram, GL_UNIFORM, "glowness");
       glProgramUniform1f(shaderProgram, glowness_loc, glowness);

       GLint resolution_loc = glGetProgramResourceLocation(shaderProgram, GL_UNIFORM, "resolution");
       glProgramUniform2f(shaderProgram, resolution_loc,  1920, 1080);

   }
}

int main()
{
    sfRenderWindow *window;
    sfEvent event;
    sfVideoMode mode = sfVideoMode_getDesktopMode();
    window = sfRenderWindow_create(mode, "CSFML Audio Visualizer", sfFullscreen, NULL);
    sfRenderWindow_setFramerateLimit(window, 60);
    glViewport(0, 0, mode.width, mode.height);
    update(window, event);
}
